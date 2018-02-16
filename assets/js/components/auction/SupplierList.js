import React from 'react';

export default class SupplierList extends React.Component {
  componentDidMount() {
    const inviteCheckboxes = Array.from(document.querySelectorAll(".invite-selector__checkbox"));
    const selectAllSellers = document.querySelector('#selectAllSellers');
    const deselectAllSellers = document.querySelector('#deselectAllSellers');

    for(var i = 0; i < inviteCheckboxes.length; i++) {inviteCheckboxes[i].addEventListener("mouseleave", function () {
        this.querySelector('input[type="checkbox"]').blur();
      });
    }

    // Set to "checked" when select all is clicked.
    selectAllSellers.addEventListener("click", function( event ) {
      for(var i = 0; i < inviteCheckboxes.length; i++) {
        inviteCheckboxes[i].querySelector('input[type="checkbox"]').checked = true;
      }
    }, true);

    // Remove checked status when deselect all is clicked;
    deselectAllSellers.addEventListener("click", function( event ) {
      for(var i = 0; i < inviteCheckboxes.length; i++) {
        inviteCheckboxes[i].querySelector('input[type="checkbox"]').checked = false;
      }
    }, true);
  }


  render() {
    return(
    <section className="auction-info">
      <div className="container is-fullhd has-padding-top-lg has-padding-bottom-lg">
        <div className="content"> <fieldset> <legend className="subtitle is-4">Invited Suppliers</legend>
            <p className="has-text-weight-bold is-5 has-margin-bottom-sm">[Selected Port Name]</p>

            <div className="invite-selector is-rounded">
              <label className="invite-selector__checkbox" htmlFor="invite-1">
                <input type="checkbox" id="invite-1"/>
                <span className="invite-selector__facade"></span>
                <span className="invite-selector__label">Supplier 1</span>
              </label>
              <label className="invite-selector__checkbox" htmlFor="invite-2">
                <input type="checkbox" id="invite-2"/>
                <span className="invite-selector__facade"></span>
                <span className="invite-selector__label">Supplier 2</span>
              </label>
              <label className="invite-selector__checkbox" htmlFor="invite-3">
                <input type="checkbox" id="invite-3"/>
                <span className="invite-selector__facade"></span>
                <span className="invite-selector__label">Supplier 3</span>
              </label>
                <label className="invite-selector__checkbox" htmlFor="invite-4">
                <input type="checkbox" id="invite-4"/>
                <span className="invite-selector__facade"></span>
                <span className="invite-selector__label">Supplier 4</span>
              </label>
            </div>
            <div className="field has-addons">
              <div className="control">
                <a id="selectAllSellers" className="button">
                  <span className="icon is-small">
                    <i className="fas fa-plus"></i>
                  </span>
                  <span className="is-inline-block has-margin-left-xs">Select All</span>
                </a>
              </div>
              <div className="control">
                <a id="deselectAllSellers" className="button">
                  <span className="icon is-small">
                    <i className="fas fa-minus"></i>
                  </span>
                  <span className="is-inline-block has-margin-left-xs">Deselect All</span>
                </a>
              </div>
            </div>
          </fieldset>
        </div>
      </div>
    </section>
    );
  }
}
