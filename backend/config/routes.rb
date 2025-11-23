Rails.application.routes.draw do
  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  delete "/logout", to: "auth#logout"
end