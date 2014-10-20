collection false

node :data do
  @history_of_digital_hello.each_with_index.map do |history, i|
    @opponent = history
    {"conversation#{i}" => partial("api/conversations/base", object: history)}
  end
end




