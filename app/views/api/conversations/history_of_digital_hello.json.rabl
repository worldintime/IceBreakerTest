collection false

node :success do
    true
end

node :data do
    i = -1
  Hash[@history_of_digital_hello.map do |history|
    @history = history
    ["conversation#{i += 1}", partial("api/conversations/base", object: history)]
  end]
end

node :fb_share do
   @fb_share
end

node :status do
    200
end






