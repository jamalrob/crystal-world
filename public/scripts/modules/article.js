export const Article = function(params) {

  /*
    Factory function for state management in article
    properties form
  */

  const articleId = params.articleId;
  const alertUnpublishedChanges = params.alertUnpublishedChanges;
  const alertArticleStatus = params.alertArticleStatus;
  const confAfterRequest = params.confAfterRequest;
  const btRevert = params.btRevert;
  const btPublish = params.btPublish;
  const btUnpublish = params.btUnpublish;
  const inputs = params.inps;
  const btPublishAction = params.btPublishAction;
  const alertPublishErrors = params.alertPublishErrors
  let isDraft = params.isDraft;
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

  const states = {
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

  const events = {
    /*
      These determine the current state
    */
    mainLoad:() => {
      let currentState = {};
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
      let currentState = {};

      const SHOW_SIGNAL_FOR = 2000;
      const DO_AUTOSAVE_AFTER = 1500; // Following last input/change event

      clearTimeout(inpEl._timer);
      inpEl._timer = setTimeout(()=>{

        localStorage.setItem(`article_${articleId}_${inpEl.name}`, inpEl.value)
        let signalEl = inpEl.labels[0].querySelector(".autosaved")
        signalEl.classList.remove("hidden");
        setTimeout(() => {
          signalEl.classList.add("hidden");
        }, SHOW_SIGNAL_FOR);

        if (isDraft !== 1) {
          dataSource = "localStorage"
          currentState = states.published.changes;
        } else {
          currentState = states.draft;
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
      let storageKeyPrefix = 'article_' + articleId;

      localStorage.removeItem(storageKeyPrefix);

      for(const input of inputs){
        let storageKey = storageKeyPrefix + "_" + input.name;
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
      }, SHOW_SIGNAL_FOR);
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
      let currentState = states.draft;
      currentState.signalling.UIState();
      setTimeout(() => {
        currentState.UIState();
      }, 2500);
      /*
        Remove error messages
      */
      alertPublishErrors.innerHTML = "";
      alertPublishErrors.classList.add("hidden");
    },
    receivePublishError:(validation_results) => {
      let currentState = states.publishError;
      currentState.UIState(validation_results);
    }
  }
  return { events };
}