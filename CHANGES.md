TODO:
* api to add your own task.

lots of work on the DSL specific parts.
    Graph and Sequence to make it easier to wire anything.
    macros can now add/modify the wiring, e.g. their end to the our end or the next task.
    [ use circuit for actual step_args/initialize process, too? ]
    You can now add an unlimited number of "your own" end events, which can then be interpreted on the outside (e.g. Endpoint)
* Introduced the `fast_track: true` option for steps. If you were returning `Railway.fail_fast!` and the like, you now need to declare that option, e.g.

        ```ruby
        step :my_validate!, fast_track: true
        ```

params:, rest: ..

## 0.2.5

* Minor fixes for activity 0.5.2.

## 0.2.4

*  Use `Activity::FastTrack` signals.

## 0.2.2

* Use `activity-0.4.2`.

## 0.2.1

* Use `activity-0.4.1`.

## 0.2.0

* Cleanly separate `Activity` and `Operation` responsibilities. An operation is nothing more but a class around an activity, hosting instance methods and implementing inheritance.

## 0.1.4

* `TaskWrap.arguments_for_call` now returns the correct `circuit_options` where the `:runner` etc.'s already merged.

## 0.1.3

* New taskWrap API for `activity` 0.3.2.

## 0.1.2

* Add @mensfeld's "Macaroni" step style for a keyword-only signature for steps.

## 0.1.0

inspect: failure is << and success is >>

call vs __call__: it's now designed to be run in a composition where the skills stuff is done only once, and the reslt object is not necessary

    FastTrack optional
    Wrapped optional

* Add `pass` and `fail` as four-character aliases for `success` and `failure`.
* Remove `Uber::Callable` requirement and treat all non-`:symbol` steps as callable objects.
* Remove non-kw options for steps. All steps receive keyword args now:

    ```ruby
    def model(options)
    ```

    now must have a minimal signature as follows.

    ```ruby
    def model(options, **)
    ```
* Remove `Operation#[]` and `Operation#[]=`. Please only change state in `options`.
* API change for `step Macro()`: the macro's return value is now called with the low-level "Task API" signature `(direction, options, flow_options)`. You need to return `[direction, options, flow_options]`. There's a soft-deprecation warning.
* Remove support for Ruby 1.9.3 for now. This can be re-introduced on demand.
* Remove `pipetree` in favor of [`trailblazer-circuit`](https://github.com/trailblazer/trailblazer-circuit). This allows rich workflows and state machines in an operation.
* Remove `uber` dependency.

## 0.0.13

* Rename `Operation::New` to `:Instantiate` to avoid name clashes with `New` operations in applications.
* Fix Ruby > 2.3.3's `Forwardable` issue.

## 0.0.12

* Allow passing tmp options into `KW::Option` that will be merged with `options` and then transformed into kw args, but only locally for the step scope (or wherever you do `Option.()`). The API:

    ```ruby
    Option::KW.(proc).(input, options, some: "more", ...)
    ```
  Note that `KW::Option` could be massively sped up with simple optimizations.

## 0.0.11

* Use `Forwardable` instead of `Uber::Delegates`.

## 0.0.10

* `Flow` is now `Railway`.
* Any `Right` subclass will now be interpreted as success.
* Add `fail!`, `fail_fast!`, `pass!`, and `pass_fast!`.
* The only semi-public method to modify the pipe is `Railway#add`
* Removed `&`, `>`, `<` and `%` "operators" in favor of `#add`.
* Extremely simplified the macro API. Macros now return a callable step with the interface `->(input, options)` and their pipe options, e.g. `[ step, name: "my.macro"]`.

## 0.0.9

Removing `Operation::consider`, which is now `step`.
We now have three methods, only.

* `step` import macro or add step with the & operator, meaning its result is always evaluated and
decides about left or right.
* `success` always adds to right track.
* `failure` always adds to left track.

This was heavily inspired by a discussion with @dnd, so, thanks! 🍻

## 0.0.8

* Introduce a new keyword signature for steps:

    ```ruby
    step ->(options, params:, **) { options["x"] = params[:id] }
    ```

    The same API works for instance methods and `Callable`s.

    Note that the implementation of `Option` and `Skills#to_hash` are improveable, but work just fine for now.


## 0.0.7

* Simplify inheritance by basically removing it.

## 0.0.6

* Improvements with the pipe DSL.

## 0.0.5

* `_insert` provides better API now.

## 0.0.4

* Don't pass the operation into `Result`, but the `Skill` options hash, only.

## 0.0.3

* Add `#inspect(slices)`.

## 0.0.2

* Works.
