class Swagger::Docs::Config
  def self.transform_path(path, api_version)
    "/api-spec/#{path}"
  end
end

Swagger::Docs::Config.register_apis({
  "1.0" => {
    # the extension used for the API
    api_extension_type: :json,
    # the output location where your .json files are written to
    api_file_path: "public/api-spec",
    # the URL base path to your API
    base_path: "/",
    # if you want to delete all .json files at each generation
    clean_directory: true,
    # add custom attributes to api-docs
    attributes: {
      info: {
        "title" => "Ice Br8kr API",
        "description" => "This is API for Ice Br8kr mobile application",
        "contact" => "seniorigor@gmail.com"
      }
    }
  }
})
