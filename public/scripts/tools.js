// Encoding UTF-8 ⇢ base64
function b64EncodeUnicode(str) {
    return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function(match, p1) {
        return String.fromCharCode(parseInt(p1, 16))
    }))
}

// Decoding base64 ⇢ UTF-8
function b64DecodeUnicode(str) {
    return decodeURIComponent(Array.prototype.map.call(atob(str), function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)
    }).join(''))
}

document.body.addEventListener('htmx:configRequest', function(evt) {
    let target = evt.detail.target
    let headers = evt.detail.headers
    let params = evt.detail.parameters

    if(target.tagName === 'FORM' && target.classList.contains("login")) {
        headers['Authorization'] = "Basic " + b64EncodeUnicode(params.username + ":" + params.password);
        params.username = '';
        params.password = '';
    }
    //evt.detail.parameters.password = b64EncodeUnicode(evt.detail.parameters.password); // add a new parameter into the mix
});