const Article = class {

  constructor(params) {
    this.articleId = params.articleId;
    this.isDraft = params.isDraft;
    this.alertUnpublishedChanges = params.alertUnpublishedChanges;
    this.alertArticleStatus = params.alertArticleStatus;
    this.confAfterRequest = params.confAfterRequest;
    this.btRevert = params.btRevert;
    this.btPublish = params.btPublish;
    this.btUnpublish = params.btUnpublish;
    this.inputs = params.inps;
    this.btPublishAction = params.btPublishAction;
    this.alertPublishErrors = params.alertPublishErrors
    this.dataSource = this.getDataSource();
    this.events.mainLoad()
  }

  getDataSource() {
    /*
      Find out if there are any items in localStorage
      for this article
    */
    let dSrc = "db";
    let storageKeyPrefix = 'article_' + this.articleId;
    if (localStorage.getItem(storageKeyPrefix) !== null){
      dSrc = "localStorage";
    }
    for(const input of this.inputs){
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
          this.confAfterRequest.innerHTML = "✔ Published";
          this.confAfterRequest.classList.add("autosaved");
        }
      },
      changes:{
        UIState:() => {
          this.isDraft = 0;
          this.alertUnpublishedChanges.innerText = 'There are unpublished changes';
          this.btRevert.classList.remove("hidden");
          this.btUnpublish.classList.remove("hidden");
          this.btPublish.classList.remove("hidden");
          this.alertArticleStatus.innerHTML = "published";
          this.confAfterRequest.innerHTML = "";
          this.confAfterRequest.classList.remove("autosaved");
          this.btPublishAction.innerHTML = "Publish changes"
        }
      },
      noChanges: {
        UIState:() => {
          this.isDraft = 0;
          this.btUnpublish.classList.remove("hidden");
          this.btPublish.classList.add("hidden");
          this.alertUnpublishedChanges.innerText = '';
          if(this.btRevert !== null) {
            this.btRevert.classList.add("hidden");
          }
          this.alertArticleStatus.innerHTML = "published";
          this.confAfterRequest.innerHTML = "";
          this.confAfterRequest.classList.remove("autosaved");
        }
      }
    },
    draft:{
      signalling:{
        UIState:() => {
          this.confAfterRequest.innerHTML = "✔ Unpublished";
          this.confAfterRequest.classList.add("autosaved");
        }
      },
      UIState:() => {
        this.isDraft = 1;
        this.alertUnpublishedChanges.innerText = '';
        this.btUnpublish.classList.add("hidden");
        this.btPublish.classList.remove("hidden");
        if(this.btRevert !== null) {
          this.btRevert.classList.add("hidden");
        }
        this.alertArticleStatus.innerHTML = "draft";
        this.confAfterRequest.innerHTML = "";
        this.confAfterRequest.classList.remove("autosaved");
        this.btPublishAction.innerHTML = "Publish"
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
        this.alertPublishErrors.innerHTML = errorMsg;
        this.alertPublishErrors.classList.remove("hidden");
      }
    }
  }

  events = {
    /*
      These determine the current state
    */
    mainLoad:() => {
      if(parseInt(this.isDraft) == 0){
        if(this.dataSource === "localStorage"){
          this.currentState = this.states.published.changes;
        } else {
          this.currentState = this.states.published.noChanges;
        }
      } else {
        this.currentState = this.states.draft;
      }
      this.currentState.UIState();
    },
    autosave:(inpEl) => {
      clearTimeout(inpEl._timer);
      inpEl._timer = setTimeout(()=>{
        localStorage.setItem(`article_${this.articleId}_${inpEl.name}`, inpEl.value)
        let signalEl = inpEl.labels[0].querySelector(".autosaved")
        signalEl.classList.remove("hidden");
        setTimeout(() => {
          signalEl.classList.add("hidden");
        }, 2000);

        if (this.isDraft !== 1) {
          this.dataSource = "localStorage"
          this.currentState = this.states.published.changes;
        } else {
          this.currentState = this.states.draft;
        }
        this.currentState.UIState();
      }, 1500);
    },
    publish:() => {
      /*
        Remove the localStorage items
        for the current article
      */
      let storageKeyPrefix = 'article_' + this.articleId;
      localStorage.removeItem(storageKeyPrefix)
      for(const input of this.inputs){
        let storageKey = storageKeyPrefix + "_" + input.name
        localStorage.removeItem(storageKey);
      }
      this.dataSource = "db";
      /*
        Set to signalling state for a couple
        of seconds
      */
      this.states.published.signalling.UIState()
      setTimeout(() => {
        this.currentState = this.states.published.noChanges;
        this.currentState.UIState();
      }, 2500);
      /*
        Remove error messages
      */
      this.alertPublishErrors.innerHTML = "";
      this.alertPublishErrors.classList.add("hidden");
    },
    unpublish:() => {
      /*
        Set to signalling state for a couple
        of seconds
      */
      this.states.draft.signalling.UIState()
      setTimeout(() => {
        this.currentState = this.states.draft;
        this.currentState.UIState();
      }, 2500);
      /*
        Remove error messages
      */
      this.alertPublishErrors.innerHTML = "";
      this.alertPublishErrors.classList.add("hidden");
    },
    receivePublishError:(validation_results) => {
      this.currentState = this.states.publishError;
      this.currentState.UIState(validation_results);
    }
  }

} // Class Article

function setupArticle() {

  const a = new Article({
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

  const autosaveEvents = ["input", "changed"];
  const autoSaveElementIDs = [
    "inpSlug",
    "inpDate",
    "inpTitle",
    "inpDate",
    "inpTags",
    "inpMainImage",
    "selImageClass"
  ]

  autosaveEvents.forEach((eventType) => {
    document.body.addEventListener(eventType, (ev) => {
      if (autoSaveElementIDs.includes(ev.target.id)) {
        a.events.autosave(ev.target)
      }
    })
  })

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
} // setupArticle()

window.addEventListener("doSetupArticle", ()=>{
  setupArticle();
})