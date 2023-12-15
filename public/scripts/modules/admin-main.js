import { newArticle } from "./article.js"

/*
  Entry point for the article properties form
  state management
*/
window.addEventListener("doSetupArticle", ()=>{
  /*
    Triggered by HTMX via header from server:
    Header "HX-Trigger-After-Settle" = "doSetupArticle"
    sent from article_properties response (only)
  */
  setupArticle();
})


function setupArticle() {

  const a = newArticle({
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
  ];
  const syncedPairs = {inpTitle: "inpSlug"};

  autosaveEvents.forEach(eventType => {
    document.body.addEventListener(eventType, ev => {

      // Special case for auto-slugification
      if(ev.target.id==="inpTitle"){
        document.getElementById("inpSlug").value = slugify(ev.target.value);
      }

      // On to the autosave
      if (autoSaveElementIDs.includes(ev.target.id)) {
        a.events.autosave(ev.target)
        /*
          When key (property name) of syncedPairs is saved,
          value gets saved too (not vice versa)
        */
        if (syncedPairs.hasOwnProperty(ev.target.id)) {
          a.events.autosave(document.getElementById(syncedPairs[ev.target.id]))
        }

      }
    })
  })


  /*
    FORM SUBMISSION RESPONSE
  */

  document.body.addEventListener('htmx:afterRequest', ev => {
    const myTarget = ev.detail.target;
    switch (myTarget.id) {
      case "publish":
        let res = JSON.parse(ev.detail.xhr.response);
        let errors = false;
        for(const inp of res.validation_results) {
          if (inp.hasOwnProperty("error")) {
            errors = true;
          }
        }
        if(errors) {
          a.events.receivePublishError(res.validation_results)
        } else {
          a.events.publish();
        }
        break;
      case "unpublish":
        a.events.unpublish();
        break;
    }
  });

  //const filepicker = document.getElementById("inpMainImage");
  //filepicker.addEventListener("change", (event) => {
  //  const files = event.target.files;
  //  filepicker.value = files[0].name;
  //});

} // setupArticle()


/*
  Helper function
*/
export function slugify(str) {
  return String(str)
  .normalize('NFKD')
  .replace(/[\u0300-\u036f]/g, '')
  .trim()
  .toLowerCase()
  .replace(/[^a-z0-9 -]/g, '')
  .replace(/\s+/g, '-')
  .replace(/-+/g, '-');
}