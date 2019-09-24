import Config

# if Mix.env() != :prod do
# config :git_hooks,
# verbose: true,
# hooks: [
# pre_commit: [
# tasks: [
# "mix format"
# ]
# ],
# pre_push: [
# tasks: [
# "mix dialyzer --halt-exit-status"
# ]
# ]
# ]
# end

if Mix.env() == :test do
  import_config "#{Mix.env()}.exs"
end
