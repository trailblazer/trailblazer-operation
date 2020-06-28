# Trailblazer-operation

_Trailblazer's Operation implementation._

## Overview

An operation is a pattern from the Trailblazer architecture. It implements a public function such as "create user" or "archive blog post". Internally, an operation is simply a generic _activity_ that uses an existing DSL to help you creating the operation's flow.

An operation is identical to an activity with two additions.

* A public `call` method with a simplified signature `Create.call(params: params, current_user: @user)`
* It produces a `Result` object with the popular `success?` API.

An operation can be used exaclty like an activity, including nesting, tracing, etc.

## Copyright

Copyright (c) 2016-2020 Nick Sutterer <apotonick@gmail.com>

`trailblazer-operation` is released under the [MIT License](http://www.opensource.org/licenses/MIT).
