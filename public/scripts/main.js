  document.body.addEventListener("htmx:beforeSwap", (evt) => {
    if(evt.target === document.getElementById("frm-login")) {
      if(evt.detail.xhr.status === 403 || evt.detail.xhr.status === 401) {
        evt.target.querySelector(".error-message").innerHTML = "Those credentials are not recognized."
      }
    }
  })