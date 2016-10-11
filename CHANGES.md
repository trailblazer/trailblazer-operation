* In `validate`, `raise!` is not called automatically anymore as this was very specific to test environments. Since we now have the result object, you have to include ### TODO for the old exceptional behavior.
* `::call` doesn't throw exception per default
* `::run` deprecated.
