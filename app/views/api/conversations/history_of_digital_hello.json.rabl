collection false

node :data do
    i = -1
  Hash[@history_of_digital_hello.map do |history|
    @history = history
    ["conversation#{i += 1}", partial("api/conversations/base", object: history)]
  end]
end




