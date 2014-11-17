# Cordova MicAccess

Get the latest buffer data from the iOS device's microphone

# Install
Clone the project to <path> then install by typing:

```
    $ cordova plugin add <path>
```

Add some the following to index.js -> deviceReady to call the plugin

```js
	var	win = function (result) {
        alert(result);		
    }, 
    fail = function (error) {
        alert("ERROR " + error);
    };

	hello.greet("World", win, fail);
```