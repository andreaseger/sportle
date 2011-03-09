require 'net/http'
# inspired by https://gist.github.com/85990

module Sinatra
  module Plugins
    module Recaptcha
      RECAPTCHA_PRIVATE = ENV['ReCaptchaPrivateKey']
      RECAPTCHA_PUBLIC = ENV['ReCaptchaPublicKey']
      RECAPTCHA_URL = "http://www.google.com/recaptcha/api/verify"
      
      def captcha_valid?(challenge, response, private_key = Sinatra::Plugins::Recaptcha::RECAPTCHA_PRIVATE)
        begin
          res = Net::HTTP.post_form(URI.parse(RECAPTCHA_URL), { :privatekey => private_key, :remoteip => request.env["REMOTE_ADDR"], :challenge => challenge, :response => response }) if (!challenge.empty? || !response.empty?)
          res.body.index("true") == 0
        rescue
          false
        end
      end
      
      def show_captcha(public_key = Sinatra::Plugins::Recaptcha::RECAPTCHA_PUBLIC)
        %{<script type="text/javascript">
          var RecaptchaOptions = {
            theme : 'clean'
          };
          </script>
          <script type="text/javascript"
             src="http://www.google.com/recaptcha/api/challenge?k=#{public_key}">
          </script>
          <noscript>
             <iframe src="http://www.google.com/recaptcha/api/noscript?k=#{public_key}"
                 height="300" width="500" frameborder="0"></iframe><br>
             <textarea name="recaptcha_challenge_field" rows="3" cols="40"></textarea>
             <input type="hidden" name="recaptcha_response_field" value="manual_challenge">
          </noscript>}
      end
    end
  end
end