#!/usr/bin/env bash

# Default system prompt
SYSTEM_PROMPT="You are a helpful, quick assistant that provides brief and concise explanation \
to given content in at most 100 characters. If the given content is not in English, translate \
it to English. If the content is an English word, provide its meaning. If the content is a name, \
provide some info about it. For a math expression, provide a simplification, \
each step on a line following this style: \`2x=11 (subtract 7 from both sides)\`. \
If you do not know the answer, simply say 'No info available'. \
Only respond for the appropriate case and use as little text as possible."

# Get first loaded model from our new helper script
first_loaded_model=$("$(dirname "$0")/show-loaded-lmstudio-models.sh" -j | jq -r '.[0].model' 2>/dev/null) || first_loaded_model=""
model=${first_loaded_model:-"qwen/qwen3-vl-4b"}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --model) model="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Grab clipboard content
content=$(wl-paste -p | tr '\n' ' ' | head -c 2000)

# LM Studio / OpenAI Chat Completion payload
api_payload=$(jq -n \
    --arg model "$model" \
    --arg system "$SYSTEM_PROMPT" \
    --arg user "$content" \
    '{
        model: $model,
        messages: [
            {role: "system", content: $system},
            {role: "user", content: $user}
        ],
        temperature: 0.1,
        stream: false
    }')

# Call LM Studio OpenAI-compatible endpoint
response=$(curl -s http://localhost:1234/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "$api_payload" | jq -r '.choices[0].message.content' 2>/dev/null)

# Fallback if AI fails
[[ -z "$response" || "$response" == "null" ]] && response="No info available"

# Desktop Notification
if [[ ${#content} -le 30 && "$content" != *$'\n'* ]]; then
    notify-send --app-name="Text selection query" --expire-time=10000 "$content" "$response"
else
    notify-send --app-name="Text selection query" --expire-time=10000 "AI Response" "$response"
fi
