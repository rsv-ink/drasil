module MockHelper
  def mock_request(*args, base_url: Drasil::Config.base_url)
    args[1] = "#{base_url}#{args[1]}"

    WebMock.stub_request(*args)
  end

  def fixture(path)
    File.read("spec/fixtures/#{path}")
  end
end
