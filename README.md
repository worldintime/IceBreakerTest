# Ice Br8kr API

Once you have fired up your rails server for this application point your browser to:

[localhost:3000/api](http://localhost:3000/api)

You should then see the swagger-ui API homepage for this application where you can then see the documentation that has been generated and interact with the controllers.

Or use these API requests at your own discretion (list might be not full):

**SignUp**

`url: /api/users`

`type: POST`

`data: :first_name, :last_name, :gender, :email, :user_name, :password, :password_confirmation`

**SignIn**

`url: /api/sessions`

`type: POST`

`data: :email, :password`

**Logout**

`url: /api/sessions`

`type: DELETE`

`data: :authentication_token`

**Forgot password**

`url: /api/sessions/reset_password`

`type: POST`

`data: :email`

**Search designated users**

`url: /api/search`

`type: POST`

`data: :authentication_token`

**Set user's location**

`url: /api/location`

`type: POST`

`data: :authentication_token, location: { :latitude, :longitude }`
