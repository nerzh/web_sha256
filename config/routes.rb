module SimpleApp
  InstanceRoute.config do
    # Example routes:
    # get "/",         to: "main#index"
    # post "/create",  to: "main#create"
    # get "/book/:id", to: "main#show"
    
    post "/management/add_transaction",  to: "management#add_transaction"
    post "/management/add_link",         to: "management#add_link"
    get  "/management/status",           to: "management#status"
    get  "/management/sync",             to: "management#sync"
    
    get  "/blockchain/get_blocks/:num_blocks", to: "blockchain#get_blocks"
    post "/blockchain/receive_update",         to: "blockchain#receive_update"
  end
end