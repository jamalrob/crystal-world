export const newArticle = function(params) {

  /*
    Factory function for state management in article
    properties form
  */

  const me = {};
  me.articleId = params.articleId;
  me.alertUnpublishedChanges = params.alertUnpublishedChanges;
  me.alertArticleStatus = params.alertArticleStatus;
  me.confAfterRequest = params.confAfterRequest;
  me.btRevert = params.btRevert;
  me.btPublish = params.btPublish;
  me.btUnpublish = params.btUnpublish;
  me.inputs = params.inps;
  me.btPublishAction = params.btPublishAction;
  me.alertPublishErrors = params.alertPublishErrors
  me.isDraft = params.isDraft;
  me.dataSource = getDataSource();

  function getDataSource() {
    /*
      Find out if there are any items in localStorage
      for this article.

      LOCAL STORAGE USAGE SCHEME:

      E.g., for article with ID=42, we'll have the following localStorage keys:
      - "article_42", which holds the markdown for the article body
      - "article_42_title", "article_42_slug", etc. for the article properties,
      - where "title", "slug", etc. are the values of the `name` attributes for each
      - of `me.inputs` (note that select elements etc. can be in `me.inputs` too)
    */
    let dSrc = "db";
    let storageKeyPrefix = `article_${me.articleId}`;

    if (localStorage.getItem(storageKeyPrefix) !== null){
      dSrc = "localStorage";
    }

    for(const input of me.inputs){
      let storageKey = `${storageKeyPrefix}_${input.name}`;
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

  me.states = {
    published:{
      signalling:{
        UIState:() => {
          me.confAfterRequest.classList.add("autosaved");
          me.confAfterRequest.innerHTML = "✔ Published";
        }
      },
      changes:{
        UIState:() => {
          me.alertUnpublishedChanges.innerText = 'There are unpublished changes';
          me.isDraft = 0;
          me.btRevert.classList.remove("hidden");
          me.btUnpublish.classList.remove("hidden");
          me.btPublish.classList.remove("hidden");
          me.alertArticleStatus.innerHTML = "published";
          me.confAfterRequest.innerHTML = "";
          me.confAfterRequest.classList.remove("autosaved");
          me.btPublishAction.innerHTML = "Publish changes"
        }
      },
      noChanges: {
        UIState:() => {
          me.isDraft = 0;
          me.btUnpublish.classList.remove("hidden");
          me.btPublish.classList.add("hidden");
          me.alertUnpublishedChanges.innerText = '';
          if(me.btRevert !== null) {
            me.btRevert.classList.add("hidden");
          }
          me.alertArticleStatus.innerHTML = "published";
          me.confAfterRequest.innerHTML = "";
          me.confAfterRequest.classList.remove("autosaved");
        }
      }
    },
    draft:{
      signalling:{
        UIState:() => {
          me.confAfterRequest.innerHTML = "✔ Unpublished";
          me.confAfterRequest.classList.add("autosaved");
        }
      },
      UIState:() => {
        me.isDraft = 1;
        me.alertUnpublishedChanges.innerText = '';
        me.btUnpublish.classList.add("hidden");
        me.btPublish.classList.remove("hidden");
        if(me.btRevert !== null) {
          me.btRevert.classList.add("hidden");
        }
        me.alertArticleStatus.innerHTML = "draft";
        me.confAfterRequest.innerHTML = "";
        me.confAfterRequest.classList.remove("autosaved");
        me.btPublishAction.innerHTML = "Publish"
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
        me.alertPublishErrors.innerHTML = errorMsg;
        me.alertPublishErrors.classList.remove("hidden");
      }
    }
  }

  me.events = {
    /*
      These determine the current state
    */
    mainLoad:() => {
      let currentState = {};
      if(parseInt(me.isDraft) === 0){
        if(me.dataSource === "localStorage"){
          currentState = me.states.published.changes;
        } else {
          currentState = me.states.published.noChanges;
        }
      } else {
        currentState = me.states.draft;
      }
      currentState.UIState();
    },
    autosave:(inpEl) => {
      let currentState = {};

      const SHOW_SIGNAL_FOR = 2000;
      const DO_AUTOSAVE_AFTER = 1500; // Following last input/change event

      clearTimeout(inpEl._timer);
      inpEl._timer = setTimeout(()=>{

        localStorage.setItem(`article_${me.articleId}_${inpEl.name}`, inpEl.value)
        let signalEl = inpEl.labels[0].querySelector(".autosaved")
        signalEl.classList.remove("hidden");
        setTimeout(() => {
          signalEl.classList.add("hidden");
        }, SHOW_SIGNAL_FOR);

        if (me.isDraft !== 1) {
          me.dataSource = "localStorage"
          currentState = me.states.published.changes;
        } else {
          currentState = me.states.draft;
        }

        currentState.UIState();

      }, DO_AUTOSAVE_AFTER);
    },
    publish:() => {
      /*
        Remove the localStorage items
        for the current article
      */
      const SHOW_SIGNAL_FOR = 2500;
      let currentState = {};
      let storageKeyPrefix = `article_${me.articleId}`;

      localStorage.removeItem(storageKeyPrefix);

      for(const input of me.inputs){
        let storageKey = `${storageKeyPrefix}_${input.name}`;
        localStorage.removeItem(storageKey);
      }
      me.dataSource = "db";

      /*
        Set to signalling state for a couple
        of seconds
      */
      me.states.published.signalling.UIState()
      setTimeout(() => {
        currentState = me.states.published.noChanges;
        currentState.UIState();
      }, SHOW_SIGNAL_FOR);
      /*
        Remove error messages
      */
      me.alertPublishErrors.innerHTML = "";
      me.alertPublishErrors.classList.add("hidden");
    },
    unpublish:() => {
      /*
        Set to signalling state for a couple
        of seconds
      */
      let currentState = me.states.draft;
      currentState.signalling.UIState();
      setTimeout(() => {
        currentState.UIState();
      }, 2500);
      /*
        Remove error messages
      */
      me.alertPublishErrors.innerHTML = "";
      me.alertPublishErrors.classList.add("hidden");
    },
    receivePublishError:(validation_results) => {
      let currentState = me.states.publishError;
      currentState.UIState(validation_results);
    }
  }
  return me;
}