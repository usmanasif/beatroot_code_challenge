# Beatroot Code Challenge

### Prerequisites
 - Ruby 2.4.3

### Installation
```sh
$ git clone https://github.com/usmanasif/beatroot_code_challenge.git
$ cd beatroot_code_challenge
$ bundle install
```
Set Environment Variables in `config/application.yml`
```
API_BASE_URL: ''
API_TOKEN: ''
API_ACCOUNT_SLUG: ''
```

```sh
$ rails s
```

### Description
The `release_controller` is responsible for returning the required response. This is done with the help of two libs `BeatrootApi` and `XMLBuilder`.

`BeatrootAPI` is responsible for providing a clean way of fetching required data from anywhere in the app without having to worry about handling HTTP Failures or Error responses.

`XMLBuilder` module provides classes to build XML file responses. It can be extended in future to easily accomodate building XML File responses with different formats.


### Testing
To run all tests run: `rake spec` in root directory of project.
