import { makeArticle } from "./article.js"

/*
  TABLE SORTING
*/

document.querySelectorAll('[data-colnum]').forEach(el => {
  el.addEventListener("click", () => {
    sortTable(el.dataset.colnum, el)
  })
})

function sortTable(colnum, me) {
  const table = document.querySelector(".admin-table");
  let rows = Array.from(table.querySelectorAll("tr"));
  rows = rows.slice(1);
  let qs = `td:nth-child(${colnum})`;

  rows.sort( (r1,r2) => {
    let t1 = r1.querySelector(qs);
    let t2 = r2.querySelector(qs);

    if(me.dataset.sortdirection=='asc' || me.dataset.sortdirection=='unsorted'){
      return t2.textContent.localeCompare(t1.textContent);
    }
    else{
      return t1.textContent.localeCompare(t2.textContent);
    }
  });

  if(me.dataset.sortdirection=='asc' || me.dataset.sortdirection=='unsorted'){
    me.dataset.sortdirection = 'desc';
    if(me.innerHTML.indexOf('▴▾') > -1){
      me.innerHTML = me.innerHTML.replace('▴▾', '▾');
    }
    else{
      me.innerHTML = me.innerHTML.replace('▴', '▾');
    }
  } else {
    me.dataset.sortdirection = 'asc';
    if(me.innerHTML.indexOf('▴▾') > -1){
      me.innerHTML = me.innerHTML.replace('▴▾', '▴');
    }
    else{
      me.innerHTML = me.innerHTML.replace('▾', '▴');
    }
  }

  const otherElId = me.id == 'btSortByCreated' ? 'btSortByPublished' : 'btSortByCreated'
  const otherEl = document.getElementById(otherElId);

  if(otherEl.innerHTML.indexOf('▴▾') < 0){
    otherEl.innerHTML = otherEl.innerHTML.replace(/▴|▾/, '▴▾');
  }

  rows.forEach(row => table.appendChild(row));
} // sortTable()


/*
  ARTICLE PROPERTIES STATE MANAGEMENT
*/

window.addEventListener("doSetupArticle", () => {
  /*
    Triggered by HTMX via header from server:
    Header "HX-Trigger-After-Settle" = "doSetupArticle"
    sent from article_properties response (only)
  */
  setupArticle();
})

function setupArticle() {

  const article = makeArticle({
    articleId:                document.getElementById("inpArticleID").value,
    isDraft:                  document.getElementById("inpDraft").value,
    alertUnpublishedChanges:  document.getElementById("unpublished-changes"),
    alertArticleStatus:       document.getElementById("article-status"),
    confAfterRequest:         document.getElementById("confirm-published"),
    btRevert:                 document.getElementById("revert"),
    btPublish:                document.getElementById("publish"),
    btUnpublish:              document.getElementById("unpublish"),
    alertPublishErrors:       document.getElementById("error-message"),
    inputs:                   document.querySelectorAll("input, select"),
    btPublishAction:          document.getElementById("publishAction")
  })

  article.events.mainLoad();


  /*
    Autosave
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
        article.events.autosave(ev.target)
        /*
          When key (property name) of syncedPairs is saved,
          value gets saved too (not vice versa)
        */
        if (syncedPairs.hasOwnProperty(ev.target.id)) {
          article.events.autosave(document.getElementById(syncedPairs[ev.target.id]))
        }

      }
    })
  })


  /*
    Form submission response
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
          article.events.receivePublishError(res.validation_results)
        } else {
          article.events.publish();
        }
        break;
      case "unpublish":
        article.events.unpublish();
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
  FORMAT DATES ACCORDING TO LOCALE
*/
document.querySelectorAll('[data-js-formatdate]').forEach(el => {
  let thisDate = new Date(el.innerHTML);
  el.innerHTML = new Intl.DateTimeFormat(navigator.language).format(thisDate);
})


/*
  IMAGE UPLOAD PROGRESS & IMAGE LIST UPDATE
*/
document.body.addEventListener('htmx:beforeRequest', ev => {
  let imgUpload = document.getElementById("imageUpload");
  if (ev.target === imgUpload) {
    const template = document.querySelector("#empty-item"); // HTML template
    const clone = template.content.cloneNode(true);
    const imageList = document.getElementById("imagelist")
    imageList.prepend(clone);
  }
})
document.body.addEventListener('htmx:afterRequest', ev => {
  let imgUpload = document.getElementById("imageUpload");
  if (ev.target === imgUpload) {
    const li = document.querySelector(".empty-item");
    li.remove();
  }
})

/*
  PRELOAD BIG IMAGES
*/
document.body.addEventListener('htmx:afterRequest', (ev) => loadBigImages(ev))

async function loadBigImages(ev) {
  const imageList = document.getElementById("imagelist");
  if (ev.target === imageList) {
    const templates = document.querySelectorAll(".bigimg");
    templates.forEach(template => {
      let clone = template.content.cloneNode(true);
      const img = new Image(960);
      img.src = clone.firstElementChild.src;
    })
  }
}

/*
  HELPERS
*/
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