# Rails Event Sourcing
[![gem version](https://badge.fury.io/rb/rails-event-sourcing.svg)](https://rubygems.org/gems/rails-event-sourcing)
[![linters](https://github.com/blocknotes/rails-event-sourcing/actions/workflows/linters.yml/badge.svg)](https://github.com/blocknotes/rails-event-sourcing/actions/workflows/linters.yml)
[![specs](https://github.com/blocknotes/rails-event-sourcing/actions/workflows/specs.yml/badge.svg)](https://github.com/blocknotes/rails-event-sourcing/actions/workflows/specs.yml)

This gem provides features to setup an event sourcing application using ActiveRecord.
ActiveJob is necessary only to use async callbacks.

> DISCLAIMER: this project is in alpha stage

The main components are:
- **event**: track state changes for an application model;
- **command**: wrap events creation;
- **dispatcher**: events' callbacks (sync and async).

This gem adds a layer to handle events for the underlying application models. In short:
- setup: an event model is created for each "event-ed" application model;
- usage: creating/updating/deleting application entities is applied via events;
- every change to an application model (named _aggregate_ in the event perspective) is stored in an event record;
- querying application models is the same as usual.

:star: if you like it, please.

A sample usage workflow:

```rb
# Load a plain Post model:
post = Post.find(1)
# Update that post's description:
Posts::ChangedDescriptionEvent.create!(post: post, description: 'My beautiful post content')
# Create a new post:
Posts::CreatedEvent.create!(title: 'New post!', description: 'Another beautiful post')
# List events for an aggregated entity (in this case Posts::Event is a STI base class for the events):
events = Posts::Event.events_for(post)
# Rollback the post to a specific version:
events[2].rollback!
# The aggregated entity is restored to the specific state, the events above that point are removed
```

:information_source: this project is based on the [event-sourcing-rails-todo-app-demo](https://github.com/pcreux/event-sourcing-rails-todo-app-demo) proposed by [Philippe Creux](https://github.com/pcreux) and his [video presentation](https://www.youtube.com/watch?v=ulF6lEFvrKo) for the Rails Conf 2019 :rocket:

## Usage

- Add to your Gemfile: `gem 'rails-event-sourcing'` (and execute `bundle`)
- Create a migration per model to store the related events, example for a User model:
`bin/rails generate migration CreateUserEvents type:string user:reference data:text metadata:text`
- Create the required events, example to create a User:
```rb
module Users
  class CreatedEvent < RailsEventSourcing::BaseEvent
    self.table_name = 'user_events' # usually this fits better in a base class using STI

    belongs_to :user, autosave: false

    data_attributes :name

    def apply(user)
      # this method will be applied when the event is created
      user.name = name
      # the aggregated entity must be returned
      user
    end
  end
end
```
- Create an event (which applies the User creation) with: `Users::CreatedEvent.create!(name: 'Some user')`
- Optionally define a create Command, for example:
```rb
module Users
  class CreateCommand
    include RailsEventSourcing::Command

    attributes :user, :name

    def build_event
      # this method will prepare the event when the command is executed
      Users::CreatedEvent.new(user_id: user.id, name: name)
    end
  end
end
```
- Invoke it with: `Users::CreateCommand.call(name: 'Some name')`

Please take a look at the [dummy app](spec/dummy/app) for a complete example.
In this case I preferred to store events models in _app/events_, commands in _app/commands_ and dispatchers in _app/dispatchers_ - but this is not mandatory. Another option could be to have an `Events` namespace and a single event could be: `Events::TodoItem::CreatedEvent`.

## Examples

Events:
```rb
TodoLists::Created.create!(name: 'My TODO 1')
TodoLists::NameUpdated.create!(name: 'My TODO!', todo_list: TodoList.first)
TodoItems::Created.create!(todo_list_id: TodoList.first.id, name: 'First item')
TodoItems::Completed.create!(todo_item: TodoItem.last)
```

Commands:
```rb
TodoLists::Create.call(name: 'My todo')
TodoItems::Create.call(todo_list: TodoList.first, name: 'Some task')
```

Dispatchers:
```rb
class TodoItemsDispatcher < RailsEventSourcing::EventDispatcher
  on TodoItems::Created, trigger: ->(todo_item) { puts ">>> TodoItems::Created [##{todo_item.id}]" }
  on TodoItems::Completed, async: Notifications::TodoItems::Completed
end
# When the event TodoItems::Created is created the trigger callback is executed
# When the event TodoItems::Completed is created a job to create a Notifications::TodoItems::Completed event is scheduled
```

## To do

- [ ] Generators for events, commands and dispatchers
- [ ] Database specific optimizations
- [ ] Add more usage examples

## Do you like it? Star it!

If you use this component just star it. A developer is more motivated to improve a project when there is some interest.

Or consider offering me a coffee, it's a small thing but it is greatly appreciated: [about me](https://www.blocknot.es/about-me).

## Contributors

- [Mattia Roccoberton](https://www.blocknot.es): author

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
