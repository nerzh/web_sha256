module SimpleApp
  InstanceRoute.config do
    # Example routes:
    # get "/",         to: "main#index"
    # post "/start",   to: "game#start"

    get "/last_blocks/:amount", to: "main#index"
    post "/add_data",           to: "main#create"
  end
end