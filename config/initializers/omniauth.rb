OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '334523600058919', 'fc60480ab600e1002cd42ed598448f6d',
           scope: 'email,user_birthday,read_stream', display: 'popup'
end