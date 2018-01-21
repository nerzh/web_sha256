module SimpleApp
  InstanceRoute.config do
    # Example routes:
    # get "/",         to: "main#index"
    # post "/start",   to: "game#start"

    post "/add_data",           to: "main#index"
    get "/last_blocks/:amount", to: "main#index"
  end
end