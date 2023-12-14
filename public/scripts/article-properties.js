function createArticle(params) {

  /*
    Factory function for state management in article
    properties form: templates/admin/article_properties.html
  */

  let articleId = params.articleId;
  let isDraft = params.isDraft;
  let alertUnpublishedChanges = params.alertUnpublishedChanges;
  let alertArticleStatus = params.alertArticleStatus;
  let confAfterRequest = params.confAfterRequest;
  let btRevert = params.btRevert;
  let btPublish = params.btPublish;
  let btUnpublish = params.btUnpublish;
  let inputs = params.inps;
  let btPublishAction = params.btPublishAction;
  let alertPublishErrors = params.alertPublishErrors
  let dataSource = getDataSource();

  function getDataSource() {
    /*
      Find out if there are any items in localStorage
      for this article
    */
    let dSrc = "db";
    let storageKeyPrefix = 'article_' + articleId;
    if (localStorage.getItem(storageKeyPrefix) !== null){
      dSrc = "localStorage";
    }
    for(const input of inputs){
      let storageKey = storageKeyPrefix + "_" + input.name
      if (localStorage.getItem(storageKey) !== null) {
        /*
          Replace input values with localStorage values
        */
        input.value = localStorage.getItem(storageKey);
        dSrc = "localStorage";
      }
    }
    return dSrc;
  }

  states = {
    published:{
      signalling:{
        UIState:() => {
          confAfterRequest.innerHTML = "✔ Published";
          confAfterRequest.classList.add("autosaved");
        }
      },
      changes:{
        UIState:() => {
          isDraft = 0;
          alertUnpublishedChanges.innerText = 'There are unpublished changes';
          btRevert.classList.remove("hidden");
          btUnpublish.classList.remove("hidden");
          btPublish.classList.remove("hidden");
          alertArticleStatus.innerHTML = "published";
          confAfterRequest.innerHTML = "";
          confAfterRequest.classList.remove("autosaved");
          btPublishAction.innerHTML = "Publish changes"
        }
      },
      noChanges: {
        UIState:() => {
          isDraft = 0;
          btUnpublish.classList.remove("hidden");
          btPublish.classList.add("hidden");
          alertUnpublishedChanges.innerText = '';
          if(btRevert !== null) {
            btRevert.classList.add("hidden");
          }
          alertArticleStatus.innerHTML = "published";
          confAfterRequest.innerHTML = "";
          confAfterRequest.classList.remove("autosaved");
        }
      }
    },
    draft:{
      signalling:{
        UIState:() => {
          confAfterRequest.innerHTML = "✔ Unpublished";
          confAfterRequest.classList.add("autosaved");
        }
      },
      UIState:() => {
        isDraft = 1;
        alertUnpublishedChanges.innerText = '';
        btUnpublish.classList.add("hidden");
        btPublish.classList.remove("hidden");
        if(btRevert !== null) {
          btRevert.classList.add("hidden");
        }
        alertArticleStatus.innerHTML = "draft";
        confAfterRequest.innerHTML = "";
        confAfterRequest.classList.remove("autosaved");
        btPublishAction.innerHTML = "Publish"
      }
    },
    publishError:{
      UIState:(validation_results) => {
        let errorMsg = "";
        for(const inp of validation_results) {
          if (inp.error !== undefined) {
            errorMsg += `${inp.name}: ${inp.error.message}<br>`
          }
        }
        alertPublishErrors.innerHTML = errorMsg;
        alertPublishErrors.classList.remove("hidden");
      }
    }
  }

  events = {
    /*
      These determine the current state
    */
    mainLoad:() => {
      if(parseInt(isDraft) === 0){
        if(dataSource === "localStorage"){
          currentState = states.published.changes;
        } else {
          currentState = states.published.noChanges;
        }
      } else {
        currentState = states.draft;
      }
      currentState.UIState();
    },
    autosave:(inpEl) => {
      clearTimeout(inpEl._timer);
      inpEl._timer = setTimeout(()=>{
        localStorage.setItem(`article_${articleId}_${inpEl.name}`, inpEl.value)
        let signalEl = inpEl.labels[0].querySelector(".autosaved")
        signalEl.classList.remove("hidden");
        setTimeout(() => {
          signalEl.classList.add("hidden");
        }, 2000);

        if (isDraft !== 1) {
          dataSource = "localStorage"
          currentState = states.published.changes;
        } else {
          currentState = states.draft;
        }
        currentState.UIState();
      }, 1500);
    },
    publish:() => {
      /*
        Remove the localStorage items
        for the current article
      */
      let storageKeyPrefix = 'article_' + articleId;
      localStorage.removeItem(storageKeyPrefix)
      for(const input of inputs){
        let storageKey = storageKeyPrefix + "_" + input.name
        localStorage.removeItem(storageKey);
      }
      dataSource = "db";
      /*
        Set to signalling state for a couple
        of seconds
      */
      states.published.signalling.UIState()
      setTimeout(() => {
        currentState = states.published.noChanges;
        currentState.UIState();
      }, 2500);
      /*
        Remove error messages
      */
      alertPublishErrors.innerHTML = "";
      alertPublishErrors.classList.add("hidden");
    },
    unpublish:() => {
      /*
        Set to signalling state for a couple
        of seconds
      */
      states.draft.signalling.UIState()
      setTimeout(() => {
        currentState = states.draft;
        currentState.UIState();
      }, 2500);
      /*
        Remove error messages
      */
      alertPublishErrors.innerHTML = "";
      alertPublishErrors.classList.add("hidden");
    },
    receivePublishError:(validation_results) => {
      currentState = states.publishError;
      currentState.UIState(validation_results);
    }
  }
  return { events }
}

function setupArticle() {

  const a = createArticle({
    articleId:                document.getElementById("inpArticleID").value,
    isDraft:                  document.getElementById("inpDraft").value,
    alertUnpublishedChanges:  document.getElementById("unpublished-changes"),
    alertArticleStatus:       document.getElementById("article-status"),
    confAfterRequest:         document.getElementById("confirm-published"),
    btRevert:                 document.getElementById("revert"),
    btPublish:                document.getElementById("publish"),
    btUnpublish:              document.getElementById("unpublish"),
    alertPublishErrors:       document.getElementById("error-message"),
    inps:                     document.querySelectorAll("input, select"),
    btPublishAction:          document.getElementById("publishAction")
  })

  a.events.mainLoad();


  /*
    AUTOSAVE
  */

  const autosaveEvents = ["input", "change"];
  const autoSaveElementIDs = [
    "inpSlug",
    "inpDate",
    "inpTitle",
    "inpDate",
    "inpTags",
    "selImageClass"
  ]

  autosaveEvents.forEach((eventType) => {
    document.body.addEventListener(eventType, (ev) => {
      if (autoSaveElementIDs.includes(ev.target.id)) {
        a.events.autosave(ev.target)

        /*
          Special rule to ensure auto-slugified value
          for slug is autosaved
        */
        if (ev.target.id === 'inpTitle'){
          a.events.autosave(document.getElementById("inpSlug"))
        }
      }
    })
  })


  /*
    FORM SUBMISSION
  */

  document.body.addEventListener('htmx:afterRequest', (evt) => {
    const myTarget = evt.detail.target;
    switch (myTarget.id) {
      case "publish":
        let res = JSON.parse(evt.detail.xhr.response);
        errors = false;
        for(const inp of res.validation_results) {
          if (inp.hasOwnProperty("error")) {
            errors = true;
          }
        }
        if(errors) {
          a.events.receivePublishError(res.validation_results)
        } else {
          a.events.publish()
        }
        break;
      case "unpublish":
        a.events.unpublish()
        break;
    }
  });

  //const filepicker = document.getElementById("inpMainImage");
  //filepicker.addEventListener("change", (event) => {
  //  const files = event.target.files;
  //  filepicker.value = files[0].name;
  //});

} // setupArticle()

window.addEventListener("doSetupArticle", ()=>{
  /*
    Triggered by HTMX via header from server:
    Header "HX-Trigger-After-Settle" = "doSetupArticle"
    sent from article_properties response (only)
  */
  setupArticle();
})

function slugify(str) {
  return String(str)
  .normalize('NFKD')
  .replace(/[\u0300-\u036f]/g, '')
  .trim()
  .toLowerCase()
  .replace(/[^a-z0-9 -]/g, '')
  .replace(/\s+/g, '-')
  .replace(/-+/g, '-');
}
