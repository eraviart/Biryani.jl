# Biryani

A data conversion and validation toolbox, written in Julia.

[![Build Status](https://travis-ci.org/eraviart/Biryani.jl.svg?branch=master)](https://travis-ci.org/eraviart/Biryani.jl)
[![Coverage Status](https://coveralls.io/repos/eraviart/Biryani.jl/badge.svg?branch=master)](https://coveralls.io/r/eraviart/Biryani.jl?branch=master)

## Quickstart

```julia
julia> Pkg.add("Biryani")

julia> using Biryani
```

## Usage Examples

### Example 1: Email validator

Before starting a conversion or validation, the value to convert must be wrapped in a `Convertible` object. A `Convertible` contains 3 fields:
- The value
- A conversion context
- An error

```julia
julia> convertible = Convertible("John@DOE.name")
Convertible("John@DOE.name",EmptyContext(),nothing)
```

Every converter accepts a `Convertible` as argument and returns another Convertible:

```julia
julia> input_to_email(convertible)
Convertible("john@doe.name",EmptyContext(),nothing)
```

Operations can be chained using the `|>` operator:

```julia
julia> Convertible("John@DOE.name") |> input_to_email
Convertible("john@doe.name",EmptyContext(),nothing)
```

```julia
julia> Convertible("   \n  ") |> input_to_email
Convertible(nothing,EmptyContext(),nothing)
```

```julia
julia> Convertible("John.DOE.name") |> input_to_email
Convertible("john.doe.name",EmptyContext(),"An email must contain exactly one \"@\".")
```

The value of a convertible can be extracted using the `to_value` function:

```julia
julia> Convertible("John@DOE.name") |> input_to_email |> to_value
"john@doe.name"
```

When conversion has failed (the convertible has an `error` field), `to_value` throws an exception instead of returning the value:

```julia
julia> Convertible("John.DOE.name") |> input_to_email |> to_value
ERROR: An email must contain exactly one "@".
Value: john.doe.name
 in to_value at .../Biryani.jl:571
 in |> at ./operators.jl:178
```

When you don't want an exception to be thrown, use the `to_value_error` function instead of `to_value`. It returns a couple `(value, error)`:

```julia
julia> value, error = Convertible("John@DOE.name") |> input_to_email |> to_value_error
("john@doe.name",nothing)

julia> value, error = Convertible("John.DOE.name") |> input_to_email |> to_value_error
("john.doe.name","An email must contain exactly one \"@\".")
```

### Example 2: Required email validator

Converters can be combined together to form more complex converters:

```julia
julia> Convertible("John@DOE.name") |> input_to_email |> require |> to_value_error
("john@doe.name",nothing)

julia> Convertible("   \n  ") |> input_to_email |> require |> to_value_error
(nothing,"Missing value.")

julia> Convertible("John.DOE.name") |> input_to_email |> require |> to_value_error
("john.doe.name","An email must contain exactly one \"@\".")
```

The `pipe` converter can also be used to chain conversions:

```julia
julia> Convertible("John@DOE.name") |> pipe(input_to_email, require) |> to_value_error
("john@doe.name",nothing)
```

You can easily create new converters by combining existing ones:

```julia
julia> input_to_required_email = pipe(input_to_email, require)
(anonymous function)

julia> Convertible("John@DOE.name") |> input_to_required_email |> to_value_error
("john@doe.name",nothing)

julia> Convertible("John.DOE.name") |> input_to_required_email |> to_value_error
("john.doe.name","An email must contain exactly one \"@\".")
```

### Example 3: Web form validator

A sample validator for a web form containing the following fields:

- Username
- Password (twice)
- Email

```julia
julia> validate_form = struct(
         [
           "username" => pipe(strip, require),
           "password" => pipe(
             test(passwords -> length(passwords) == 2 && passwords[1] == passwords[2], error = "Password mismatch."),
             call(passwords -> passwords[1]),
           ),
           "email" => input_to_email,
         ],
       )

julia> input_data = [
         "username" => "   John Doe\n  ",
         "password" => ["secret", "secret"],
         "email" => "John@DOE.name",
       ]

julia> result, errors = Convertible(input_data) |> validate_form |> to_value_error
(["password"=>"secret","username"=>"John Doe","email"=>"john@doe.name"],nothing)
```

**Note:** The same validation using the classic composition of functions instead of `|>`:

```julia
julia> result, errors = to_value_error(validate_form(Convertible(input_data)))
(["password"=>"secret","username"=>"John Doe","email"=>"john@doe.name"],nothing)

julia> to_value_error(validate_form(Convertible(
         [
           "password" => ["secret", "other secret"],
           "email" => "   John@DOE.name\n  ",
         ],
       )))
(["password"=>ASCIIString["secret","other secret"],"username"=>nothing,"email"=>"john@doe.name"],["password"=>"Password mismatch.","username"=>"Missing value."])
```
