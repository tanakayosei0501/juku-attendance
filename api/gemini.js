// Vercel serverless function — Gemini API proxy
// Keeps GEMINI_API_KEY server-side, never exposed to browser.
// Supports actions: "transcribe" and "analyze"

async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method not allowed' }); return; }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    res.status(500).json({
      error: 'GEMINI_API_KEY が Vercel の環境変数に設定されていません。Vercel ダッシュボード → Settings → Environment Variables で設定してください。'
    });
    return;
  }

  const { action, audio_b64, mime_type, transcripts, student_name, grade } = req.body || {};

  let requestBody;

  if (action === 'transcribe') {
    if (!audio_b64) { res.status(400).json({ error: 'audio_b64 is required' }); return; }
    requestBody = {
      contents: [{
        parts: [
          {
            inlineData: {
              mimeType: (mime_type || 'audio/webm').split(';')[0],
              data: audio_b64
            }
          },
          {
            text: 'この音声は個別指導塾の授業中に先生が残したメモです。話された内容を正確に文字起こしして。文字起こし結果のテキストのみを返してください。聞き取れない部分は[不明瞭]と記載してください。'
          }
        ]
      }]
    };
  } else if (action === 'analyze') {
    if (!transcripts) { res.status(400).json({ error: 'transcripts is required' }); return; }
    const combined = Array.isArray(transcripts) ? transcripts.join('\n\n---\n\n') : transcripts;
    requestBody = {
      contents: [{
        parts: [{
          text: `あなたは個別指導塾の授業記録アシスタントです。
以下の授業音声メモの文字起こしを分析して、保護者向け報告書を作成してください。

【生徒情報】
氏名: ${student_name || '（不明）'}
学年: ${grade || '（不明）'}

【授業音声メモ（文字起こし）】
${combined}

以下の形式でJSONのみを返してください（前後に説明文や\`\`\`は不要）:
{
  "subject": "教科名（数学/英語/国語/理科/社会/算数/その他）",
  "unit": "学習した単元や内容の名称",
  "analysis": {
    "content": "本日の学習内容の要約（2〜3文）",
    "understanding": "生徒の理解状況・取り組みの様子（2〜3文、音声内容に基づく事実のみ）",
    "achievements": ["できるようになったこと・理解できた内容"],
    "issues": ["今後取り組む課題・定着が必要な内容"],
    "next_steps": ["次回の授業で取り組む予定の内容"]
  },
  "report": "保護者向け報告文。丁寧・温かみ・具体的・前向き・事実ベース。音声に含まれない内容は絶対に追加しないこと。300〜400字程度。"
}`
        }]
      }],
      generationConfig: { responseMimeType: 'application/json' }
    };
  } else if (action === 'revise') {
    const { current_text, instruction } = req.body || {};
    requestBody = {
      contents: [{
        parts: [{
          text: `以下の保護者向け報告書を、指示に従って修正してください。修正した報告書のテキストのみを返してください。説明不要です。

【現在の報告書】
${current_text}

【修正指示】
${instruction}`
        }]
      }]
    };
  } else {
    res.status(400).json({ error: `Unknown action: ${action}` });
    return;
  }

  try {
    const model = 'gemini-1.5-flash';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody)
    });

    const data = await response.json();

    if (!response.ok) {
      res.status(response.status).json({
        error: data.error?.message || 'Gemini API エラー',
        details: data
      });
      return;
    }

    res.status(200).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

handler.config = {
  api: {
    bodyParser: {
      sizeLimit: '10mb'
    }
  }
};

module.exports = handler;
