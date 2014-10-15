collection false

node :history_of_digital_hello do
  @history_of_digital_hello.map do |history|
    partial("api/conversations/base", object: history)
  end
end
