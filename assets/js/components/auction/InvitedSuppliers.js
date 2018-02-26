import React from 'react';
import _ from 'lodash';

const InvitedSuppliers = ({auction}) => {
  const suppliers = _.get(auction, 'suppliers');
  return(
    <div className="box">
      <h3 className="box__header">Invited Suppliers</h3>
      <ul className="list has-no-bullets qa-auction-suppliers">
        { _.map(suppliers, (supplier) => {
            return (
              <li key={supplier.id}>
              <span className="icon has-text-success has-margin-right-sm"><i className="fas fa-check-circle"></i></span>
              <span className={`qa-auction-supplier-${supplier.id}`}>{supplier.name}</span>
              </li>
            );
          })
        }
      </ul>
    </div>
  );
};

export default InvitedSuppliers;
