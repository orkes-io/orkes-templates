#!/bin/bash
echo "Starting the creation of the Document Classifier Application..."
# Global variables
workflow_template_URL="https://raw.githubusercontent.com/orkes-io/orkes-templates/main/document-classifier/workflows/document-classifier.json"
prompt_text_URL="https://image-processing-orkes.s3.amazonaws.com/classify-document.prompt"
current_time=$(date +%s%3)
document_classifier_input="https://image-processing-orkes.s3.amazonaws.com/test-w2-form-full-text.pdf"
openai_integ_model_name="gpt-3.5-turbo"
CONDUCTOR_SERVER_API_URL=${CONDUCTOR_SERVER_API_URL:-"https://play.orkes.io/api"}

echo "Confirming all the required environment variables are set..."
# Check for required environment variables
if [[ -z "$CONDUCTOR_ACCESS_TOKEN" && (-z "$CONDUCTOR_KEY" || -z "$CONDUCTOR_SECRET") ]]; then
    echo "Error: CONDUCTOR_ACCESS_TOKEN or both CONDUCTOR_KEY and CONDUCTOR_SECRET must be set"
    exit 1
fi

if [ -z "$OPEN_AI_KEY" ]; then
    echo "Error: OPEN_AI_KEY must be set"
    exit 1
fi

echo "Checking connectivity to Orkes Conductor server..."
# Check connectivity
response=$(curl -s -o /dev/null -w "%{http_code}" "$CONDUCTOR_SERVER_API_URL/version")
if [ "$response" -ne 200 ]; then
    echo "Error: Conductor server is not reachable"
    exit 1
fi

echo "Obtaining user information..."
# Set the token
if [ ! -z "$CONDUCTOR_ACCESS_TOKEN" ]; then
    user_info=$(curl -s -X 'GET' \
        "$CONDUCTOR_SERVER_API_URL/token/userInfo" \
        -H "X-Authorization: $CONDUCTOR_ACCESS_TOKEN")


    
    user_name=$(echo "$user_info" | jq -r '.name' | sed 's/ /_/g')
    user_id=$(echo "$user_info" | jq -r '.id' | sed 's/ /_/g')
    token=$CONDUCTOR_ACCESS_TOKEN
else
    token_response=$(curl -s -X 'POST' \
        "$CONDUCTOR_SERVER_API_URL/token" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{
        "keyId": "'"$CONDUCTOR_KEY"'",
        "keySecret": "'"$CONDUCTOR_SECRET"'"
    }')
 
    
    token=$(echo "$token_response" | jq -r '.token')
    if [ ! -z "$token" ]; then
    user_info=$(curl -s -X 'GET' \
        "$CONDUCTOR_SERVER_API_URL/token/userInfo" \
        -H "X-Authorization: $token")
    fi

    user_name=$(echo "$user_info" | jq -r '.name' | sed 's/ /_/g')
    user_id=$(echo "$user_info" | jq -r '.id' | sed 's/ /_/g')
fi

echo "Hello $user_name / $user_id"

# Create LLM provider (OpenAI) integration
echo "Creating a LLM provider integration with OpenAI..."
openai_integ_name="openai_${user_name}_${current_time}"
openai_integ_params='{
  "category": "AI_MODEL",
  "configuration": {
    "api_key": "'"${OPEN_AI_KEY}"'"
  },
  "description": "This is an OpenAI integration created by '"${user_name}"' / '"${user_id}"' at time: '"${current_time}"'",
  "enabled": true,
  "type": "openai"
}'
openai_integ_response=$(curl -s -X 'POST' \
    "$CONDUCTOR_SERVER_API_URL/integrations/provider/$openai_integ_name" \
    -H 'accept: */*' \
    -H "X-Authorization: $token" \
    -H 'Content-Type: application/json' \
    -d "$openai_integ_params")

# Add LLM model to integrationn
echo "Adding model to the integration..."
openai_integ_model_params='{
  "configuration": {},
  "description": "'"${openai_integ_model_name}"' from OpenAI",
  "enabled": true
}'
openai_integ_model_response=$(curl -s -X 'POST' \
    "$CONDUCTOR_SERVER_API_URL/integrations/provider/$openai_integ_name/integration/$openai_integ_model_name" \
    -H 'accept: */*' \
    -H "X-Authorization: $token" \
    -H 'Content-Type: application/json' \
    -d "$openai_integ_model_params")

# Add an AI prompt
echo "Creating the AI prompt to be used for this application..."
ai_prompt_name="document_classification_prompt_${user_name}_${current_time}"
ai_prompt_description=$(echo "This is a prompt to classify documents and is created using the Orkes quick start script" | jq -sRr @uri)
ai_prompt_model_association=$(echo "${openai_integ_name}:${openai_integ_model_name}" | jq -sRr @uri)
ai_prompt_text=$(curl -s "$prompt_text_URL")

prompt_response=$(curl -s -X 'POST' \
    "$CONDUCTOR_SERVER_API_URL/prompts/$ai_prompt_name?description=$ai_prompt_description&models=$ai_prompt_model_association" \
    -H 'accept: */*' \
    -H "X-Authorization: $token" \
    -H 'Content-Type: application/json' \
    -d "$ai_prompt_text")


# Create workflow
echo "Creating athe workflow for this application using the integration and prompt that were created..."
workflow_definition=$(curl  -s "$workflow_template_URL")
workflow_definition_name=$(echo "$workflow_definition" | jq -r '.name' | sed "s/ /_/g")"_$user_name_$current_time"
workflow_definition=$(echo "$workflow_definition" | \
   jq '.name = "'"$workflow_definition_name"'" |
    .tasks[] |= (if .name == "classify_using_llm" then 
        .inputParameters.promptName = "'"$ai_prompt_name"'" |
        .inputParameters.llmProvider = "'"$openai_integ_name"'" |
        .inputParameters.model = "'"$openai_integ_model_name"'" 
    else . end) |
    .updateTime = "'"$current_time"'" |
    .ownerEmail = "'"$user_id"'"')

workflow_response=$(curl -s -X 'POST' \
    "$CONDUCTOR_SERVER_API_URL/metadata/workflow?overwrite=false&newVersion=false" \
    -H 'accept: */*' \
    -H "X-Authorization: $token" \
    -H 'Content-Type: application/json' \
    -d "$workflow_definition")


CONDUCTOR_SERVER_URL=${CONDUCTOR_SERVER_API_URL%/api}

# Display success message
echo ""
echo "You have successfully created the below artifacts in Orkes Conductor:
1/ An LLM integration with OpenAI listed in: $CONDUCTOR_SERVER_URL/integrations/$openai_integ_name/integration
2/ A prompt for the document classification LLM call: $CONDUCTOR_SERVER_URL/ai_prompts/$ai_prompt_name
3/ A document classifier workflow that uses this integration and prompt: $CONDUCTOR_SERVER_URL/workflowDef/$workflow_definition_name

Follow the above URLs to visually see the artifacts
Now let's run this document classifier application with an example input"

echo "Press any key to continue..."
read -n 1 -s -r -p ""
echo ""  


# Call the workflow
echo "Calling the execution of the $workflow_definition_name workflow..."
workflow_execution_id=$(curl  -s -X 'POST' \
    "$CONDUCTOR_SERVER_API_URL/workflow/$workflow_definition_name?priority=0" \
    -H 'accept: text/plain' \
    -H "X-Authorization: $token" \
    -H 'Content-Type: application/json' \
    -d '{
    "document_url": "'"$document_classifier_input"'"
}')




# Display execution message
echo "Here is the execution view of your application. Follow this link to visually see the status and the results: $CONDUCTOR_SERVER_URL/execution/$workflow_execution_id"
echo "Checking the status of the execution..."
#!/bin/bash

# Initialize start time and timeout
start_time=$(date +%s)
timeout=30  # 30 seconds

# Loop until the timeout is reached
while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
    # Perform the curl request
    response=$(curl -s -X 'GET' \
  "$CONDUCTOR_SERVER_API_URL/workflow/$workflow_execution_id/status?includeOutput=true&includeVariables=false" \
  -H 'accept: */*' \
  -H "X-Authorization: $token")


    # Extract the status from the response
    status=$(echo $response | jq -r '.status')

    # Check if status is COMPLETED
    if [ "$status" = "COMPLETED" ]; then
        echo ""
        echo "Execution has completed..."
        llm_response=$(echo $response | jq -r '.output.result')
        echo "The result is: $llm_response"
        echo ""
        echo "Go to http://orkes.io/ai to learn more about how you can build Gen-AI powered applications!"
        break
    fi


    # Wait for 2 seconds before the next iteration
    sleep 2
done

# Optional: Check if loop exited due to timeout
if [ "$status" != "COMPLETED" ]; then
    echo "Timeout reached. Execution may not have completed. Please navigate to $CONDUCTOR_SERVER_URL/execution/$workflow_execution_id to visually inspect the execution"
fi