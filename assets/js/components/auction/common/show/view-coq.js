import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const ViewCOQ = ({fuel, supplierCOQ, deleteCOQ, allowedToDelete}) => {
  const renderCOQView = () => {
    if (supplierCOQ) {
      return (
        <div className="collapsing-barge__barge__button buttons has-addons has-margin-bottom-none">
          <a href={`/auction_supplier_coqs/${supplierCOQ.id}`} className="button is-small is-link is-text-color-white" target="_blank"><FontAwesomeIcon icon="external-link-alt" /><span>View COQ</span></a>
          {(window.isAdmin && !window.isImpersonating || allowedToDelete) ? <a className="button is-small is-danger" onClick={(e) => deleteCOQ(supplierCOQ.id)}><FontAwesomeIcon icon="times" /><span>Delete</span></a> : ""}
        </div>
      )
    } else {
      return "";
    }
  }

  return (
    <div className="content submitted has-margin-bottom-sm">
      <h2 className="collapsing-barge__barge__trigger"><span className="collapsible-section__title">{fuel.name}</span></h2>
      {renderCOQView()}
    </div>
  )

}

export default ViewCOQ;
