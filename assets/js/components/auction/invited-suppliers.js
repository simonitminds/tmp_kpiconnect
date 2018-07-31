import React from 'react';
import _ from 'lodash';
import CollapsingBarge from './collapsing-barge';

const InvitedSuppliers = ({auctionPayload, approveBargeForm, rejectBargeForm}) => {
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
  const auctionBarges = _.get(auctionPayload, 'submitted_barges');

  const auctionBargesBySupplier = auctionBarges.reduce((acc, barge) => {
    acc[barge.supplier_id] = acc[barge.supplier_id] || [];
    acc[barge.supplier_id].push(barge);
    return acc;
  }, {});

  const bargesForSupplier = (supplier) => {
    const auctionBarges = auctionBargesBySupplier[supplier.id] || [];

    return (
      <div className={`supplier__barges qa-auction-supplier-${supplier.id}-barges`}>
        { auctionBarges.map((auctionBarge) => {
            const barge = auctionBarge.barge;
            return (
              <CollapsingBarge
                trigger={ `${barge.name} (${barge.imo_number})` }
                classParentString="collapsing-barge__barge"
                easing="ease"
                open={false}
                approveBargeForm={approveBargeForm}
                rejectBargeForm={rejectBargeForm}
                auction={auctionPayload.auction}
                barge={barge}
                supplierId={auctionBarge.supplier_id}
                bargeStatus={auctionBarge.approval_status}
                isBuyer={true}
                key={barge.id}
              >
              </CollapsingBarge>
            );
          })
        }
      </div>
    );
  };

  return(
    <div className="box">
      <h3 className="box__header">Invited Suppliers</h3>
      <ul className="list has-no-bullets qa-auction-suppliers">
        { _.map(suppliers, (supplier) => {
            return (
              <div key={supplier.id}>
                <li>
                  <span className="icon has-text-success has-margin-right-sm"><i className="fas fa-check-circle"></i></span>
                  <span className={`qa-auction-supplier-${supplier.id}`}>{supplier.name}</span>
                </li>
                { bargesForSupplier(supplier) }
              </div>
            );
          })
        }
      </ul>
    </div>
  );
};

export default InvitedSuppliers;
