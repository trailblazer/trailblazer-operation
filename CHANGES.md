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
