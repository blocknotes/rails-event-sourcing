# Rails Event Sourcing

This gem provides features to setup an event sourcing application using ActiveRecord.
ActiveJob is necessary only to use async callbacks.

> DISCLAIMER: this project is in alpha stage

The main components are:
- **event**: model used to track state changes for an entity;
- **command**: wrap events creation;
- **dispatcher**: events' callbacks (sync and async).

This gem adds a layer to handle events for the underlying application models. In short:
- an event model is created for each "event-ed" application model;
- every change to an application model (named _aggregate_ in the event perspective) is stored in an event record;
- querying application models is the same as usual;
- writing changes to application entities is applied creating events.

A sample workflow can be:

```rb
# I have a plain Post model:
post = Post.find(1)
# When I need to update that post:
Posts::ChangedDescription.create!(post: post, description: 'My beautiful post content')
# When I need to create a new post:
Posts::Created.create!(title: 'New post!', description: 'Another beautiful post')
# I can query the events for an aggregated entity:
events = Posts::Event.events_for(post) # Posts::Event is usually a base class for all events for an aggregate (using STI)
# I can rollback to a specific version of the aggregated entity:
events[2].rollback! # the aggregated entity is restored to the specific state, the events above that point are removed
```

The project is based on a [demo app](https://github.com/pcreux/event-sourcing-rails-todo-app-demo) proposed by [Philippe Creux](https://github.com/pcreux) and his video presentation for Rails Conf 2019:

[![Event Sourcing made Simple by Philippe Creux](https://img.youtube.com/vi/ulF6lEFvrKo/0.jpg)](https://www.youtube.com/watch?v=ulF6lEFvrKo "Event Sourcing made Simple by Philippe Creux")

Please :star: if you like it.

## Usage

- Add to your Gemfile: `gem 'rails-event-sourcing'` (and execute `bundle`)
- Create a migration per model to store the related events, example for User:
`bin/rails generate migration CreateUserEvents type:string user:reference data:text metadata:text`
- Create the events, example for `Users::Created`:
```rb
module Users
  class Created < RailsEventSourcing::BaseEvent
    self.table_name = 'user_events' # usually this fits better in a base class using STI

    belongs_to :user, autosave: false

    data_attributes :name

    def apply(user)
      # this method will be applied when the event is created
      user.name = name
      user
    end
  end
end
```
- Invoke an event with: `Users::Created.create!(name: 'Some user')`
- Optionally create a Command, example:
```rb
module Users
  class CreateCommand
    include RailsEventSourcing::Command

    attributes :user, :name

    def build_event
      # this method will be applied when the command is executed
      Users::Created.new(user_id: user.id, name: name)
    end
  end
end
```
- Invoke a command with: `Users::CreateCommand.call(name: 'Some name')`

## Examples

Please take a look at the [dummy app](spec/dummy/app) for a detailed example.

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
# Now when the event TodoItems::Created is created the trigger callback is executed
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
