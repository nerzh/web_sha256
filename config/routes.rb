module SimpleApp
  InstanceRoute.config do
    # Example routes:
    # get "/",         to: "main#index"
    # post "/start",   to: "game#start"

    get "/last_blocks/:amount",          to: "main#index"
    post "/add_data",                    to: "main#create"
    
    post "/management/add_transaction",  to: "management#add_transaction"
    post "/management/add_link",         to: "management#add_link"
    get  "/management/status",           to: "management#status"
    get  "/management/sync",             to: "management#sync"
    
    get  "/blockchain/get_blocks/:num_blocks", to: "blockchain#get_blocks"
    post "/blockchain/receive_update",         to: "blockchain#receive_update"
    post "/blockchain/t",         to: "blockchain#t"
  end
end