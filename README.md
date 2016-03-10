# Personal Assistant Device

This application is a translation of the application constructed in Learn You Some Erlang, chapter "Designing a Concurrent Application."

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add pad to your list of dependencies in `mix.exs`:

        def deps do
          [{:pad, "~> 0.0.1"}]
        end

  2. Ensure pad is started before your application:

        def application do
          [applications: [:pad]]
        end

