environment          = "staging"
monthly_budget_limit = 200
enable_vpc_endpoints = true
max_session_duration = 7200
secret_rotation_days = 60
alert_emails         = ["staging-alerts@example.com"]

bedrock_model_ids = ["us.anthropic.claude-opus-4-7", "us.anthropic.claude-sonnet-4-20250514-v1:0", "us.anthropic.claude-3-5-haiku-20241022-v1:0"]
# Available inference profile IDs (us-east-1):
#   "us.anthropic.claude-opus-4-7"                  - Claude Opus 4.7
#   "us.anthropic.claude-opus-4-6-v1"               - Claude Opus 4.6
#   "us.anthropic.claude-opus-4-5-20251101-v1:0"    - Claude Opus 4.5
#   "us.anthropic.claude-opus-4-1-20250805-v1:0"    - Claude Opus 4.1
#   "us.anthropic.claude-opus-4-20250514-v1:0"      - Claude Opus 4
#   "us.anthropic.claude-sonnet-4-6"                - Claude Sonnet 4.6
#   "us.anthropic.claude-sonnet-4-5-20250929-v1:0"  - Claude Sonnet 4.5
#   "us.anthropic.claude-sonnet-4-20250514-v1:0"    - Claude Sonnet 4
#   "us.anthropic.claude-haiku-4-5-20251001-v1:0"   - Claude Haiku 4.5
#   "us.anthropic.claude-3-5-haiku-20241022-v1:0"   - Claude 3.5 Haiku
#   "us.anthropic.claude-3-sonnet-20240229-v1:0"    - Claude 3 Sonnet
#   "us.anthropic.claude-3-haiku-20240307-v1:0"     - Claude 3 Haiku
#   "us.anthropic.claude-3-opus-20240229-v1:0"      - Claude 3 Opus
