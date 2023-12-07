const Article = class {

  dataSource = "db";

  constructor({
    articleId,
    isDraft,
    alertUnpublishedChanges,
    alertArticleStatus,
    confAfterRequest,
    btRevert,
    btPublish,
    btUnpublish,
    inps
  }) {
    this.articleId = articleId;
    this.isDraft = isDraft;
    this.alertUnpublishedChanges = alertUnpublishedChanges;
    this.alertArticleStatus = alertArticleStatus;
    this.confAfterRequest = confAfterRequest;
    this.btRevert = btRevert;
    this.btPublish = btPublish;
    this.btUnpublish = btUnpublish;
    this.inputs = inps;
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
        input.value = localStorage.getItem(storageKey);
        dSrc = "localStorage";
      }
    }
    return dSrc;
  }

  states = {
    published:{
      signalling:{
        do:() => {
          this.confAfterRequest.innerHTML = "✔ Published";
          this.confAfterRequest.classList.add("autosaved");
        }
      },
      changes:{
        do:() => {
          this.isDraft = 0;
          this.alertUnpublishedChanges.innerText = 'There are unpublished changes';
          this.btRevert.classList.remove("hidden");
          this.btUnpublish.classList.remove("hidden");
          this.btPublish.classList.remove("hidden");
          this.alertArticleStatus.innerHTML = "published";
          this.confAfterRequest.innerHTML = "";
          this.confAfterRequest.classList.remove("autosaved");
        }
      },
      no_changes: {
        do:() => {
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
        do:() => {
          this.confAfterRequest.innerHTML = "✔ Unpublished";
          this.confAfterRequest.classList.add("autosaved");
        }
      },
      do:() => {
        this.isDraft = 1;
        this.btUnpublish.classList.add("hidden");
        this.btPublish.classList.remove("hidden");
        if(this.btRevert !== null) {
          this.btRevert.classList.add("hidden");
        }
        this.alertArticleStatus.innerHTML = "draft";
        this.confAfterRequest.innerHTML = "";
        this.confAfterRequest.classList.remove("autosaved");
      }
    }
  }

  get events() {
    /*
      These determine the current state
    */
    return {
      mainLoad:() => {
        if(parseInt(this.isDraft) == 0){
          if(this.dataSource === "localStorage"){
            this.currentState = this.states.published.changes;
          } else {
            this.currentState = this.states.published.no_changes;
          }
        } else {
          this.currentState = this.states.draft;
        }
        this.currentState.do();
      },
      autosave:(inpEl) => {
        clearTimeout(inpEl._timer);
        inpEl._timer = setTimeout(()=>{
          localStorage.setItem(`article_${a.articleId}_${inpEl.name}`, inpEl.value)
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
          this.currentState.do();
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
        this.states.published.signalling.do()
        setTimeout(() => {
          this.currentState = this.states.published.no_changes;
          this.currentState.do();
        }, 2500);
      },
      unpublish:() => {
        /*
          Set to signalling state for a couple
          of seconds
        */
        this.states.draft.signalling.do()
        setTimeout(() => {
          this.currentState = this.states.draft;
          this.currentState.do();
        }, 2500);
      },
    }
  }

} // Class