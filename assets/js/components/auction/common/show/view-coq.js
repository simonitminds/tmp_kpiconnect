import React from 'react';
import _ from 'lodash';

const ViewCOQ = ({fuel, supplierCOQ, allowedToDelete}) => {
  const renderCOQView = () => {
    if (supplierCOQ) {
      return (
        <div>
          <a href={`/auction_supplier_coqs/${supplierCOQ.id}`} target="_blank">View COQ</a>
          { (window.isAdmin && !window.isImpersonating || allowedToDelete) ? <a className="button is-danger has-margin-top-sm" onClick={(e) => deleteCOQ(supplierCOQ.id)}>Delete</a> : "" }
        </div>
      )
    } else {
      return "";
    }
  }

  return (
    <div>
      {fuel.name}
      { renderCOQView() }
    </div>
  )

}

export default ViewCOQ;
