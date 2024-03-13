module Analytics
  module OAuth
    class GetEmbedConfig
      CLIENT_ID = ENV['CLIENT_ID']
      CLIENT_SECRET = ENV['CLIENT_SECRET']
      TENANT_ID = ENV['TENANT_ID']
      POWERBI_USERNAME = ENV['POWERBI_USERNAME']
      POWERBI_PASSWORD = ENV['POWERBI_PASSWORD']

      def call
        access_token = get_access_token
        api_request_headers = get_api_request_headers(access_token)
        group_ids = get_all_groups(api_request_headers).map { |group| group['id'] }
        report_details = get_all_reports(api_request_headers, group_ids)
        embed_tokens = generate_embed_tokens(api_request_headers, report_details, group_ids)
        report_embed_configs(report_details, embed_tokens, group_ids)
      end

      private

      def get_access_token
        resource = 'https://analysis.windows.net/powerbi/api'
        body = {
          grant_type: 'password',
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          resource: resource,
          scope: 'openid',
          username: POWERBI_USERNAME,
          password: POWERBI_PASSWORD
        }

        response = HTTParty.post("https://login.microsoftonline.com/common/oauth2/token", body: body)
        response['access_token']
      end

      def get_api_request_headers(access_token)
        {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{access_token}"
        }
      end

      def get_all_groups(headers)
        url = 'https://api.powerbi.com/v1.0/myorg/groups'
        response = HTTParty.get(url, headers: headers)
        if response.success?
          response.parsed_response['value']
        else
          error_message = response.parsed_response['error']['message'] if response.parsed_response['error']
          raise "Error fetching groups: #{error_message || response.code} - #{response.message}"
        end
      end

      def get_all_reports(headers, groups)
        report_details = []
        groups.each do |group|
          url = "https://api.powerbi.com/v1.0/myorg/groups/#{group}/reports"
          response = HTTParty.get(url, headers: headers)
          if response.success?
            report_details.concat(response.parsed_response['value'])
          else
            error_message = response.parsed_response['error']['message'] if response.parsed_response['error']
            raise "Error fetching reports for group #{group['id']}: #{error_message || response.code} - #{response.message}"
          end
        end

        report_details
      end

      def generate_embed_tokens(headers, report_details, groups)
        embed_tokens = {}
        groups.map do |group|
          group_id = group
          report_details.each do |report|
            report_id = report['id']
            embed_token = generate_embed_token(headers, group_id, report_id)
            embed_tokens[report_id] = embed_token if embed_token
          end
        end
        embed_tokens
      end

      def generate_embed_token(headers, group_id, report_id)
        url = "https://api.powerbi.com/v1.0/myorg/groups/#{group_id}/reports/#{report_id}/GenerateToken"
        body = {
          accessLevel: 'view'
        }
        response = HTTParty.post(url, headers: headers, body: body.to_json)
        if response.success?
          response.parsed_response['token']
        else
          error_message = response.parsed_response['error']['message'] if response.parsed_response['error']
          puts "Error generating embed token for report #{report_id} in group #{group_id}: #{error_message || response.code} - #{response.message}"
          nil
        end
      end

      def report_embed_configs(report_details, embed_tokens, groups)
        report_configs = []

        groups.each do |group|
          report_details.each do |report|
            report_id = report['id']
            report_name = report['name']
            embed_url = report['embedUrl']
            embed_token = embed_tokens[report_id]
            report_config = {
              groupId: group,
              reportId: report_id,
              reportName: report_name,
              embedUrl: embed_url,
              embedToken: embed_token
            }

            report_configs << { report_config: report_config }
          end
        end
        report_configs
      end


    end
  end
end
