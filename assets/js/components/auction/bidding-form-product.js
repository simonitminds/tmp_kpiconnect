import React from 'react';
import _ from 'lodash';
import { formatPrice } from '../../utilities';
import CheckBoxField from '../check-box-field';
import MediaQuery from 'react-responsive';
import BidTag from './bid-tag';


const BiddingFormProduct = ({fuel, auctionPayload, onRevoke, onUpdate, supplierId}) => {
  const isMultiProduct = _.get(auctionPayload, 'auction.fuels', []).length > 1;

  const {id: fuelId, name} = fuel;
  const vesselFuels = _.chain(auctionPayload)
    .get('auction.auction_vessel_fuels')
    .filter((avf) => avf.fuel_id == fuelId)
    .value();
  const totalQuantity = _.sumBy(vesselFuels, (vf) => vf.quantity);

  const lowestFuelBid = _.chain(vesselFuels)
    .map((vf) => _.get(auctionPayload, `product_bids["${vf.id}"].lowest_bids[0]`))
    .filter()
    .minBy('amount')
    .value();

  const hasLowestBid = lowestFuelBid && (lowestFuelBid.supplier_id == supplierId)


  return(
    <div className="auction-bidding__product-group has-margin-bottom-md">
      <div className="columns is-desktop has-margin-bottom-xs">
        <div className="column is-one-quarter-desktop">
          <strong>{name}</strong><br/>
          <span className="has-text-gray-3">&times; {totalQuantity} MT </span><br/>
          <div className="control has-margin-top-sm">
            <BidTag bid={lowestFuelBid} title="Bid to Beat" highlightOwn={hasLowestBid} />
          </div>
        </div>
        <div className="column">
          <div className="columns is-desktop">
            <div className="column">
              <div className="field">
                <label className="label" htmlFor="bid">Bid Amount</label>
                <div className="control auction-bidding__input has-icons-left">
                  <span className="icon is-small is-left"><i className="fas fa-dollar-sign"></i></span>
                  <input
                    type="number"
                    step="0.25"
                    min="0"
                    className="input qa-auction-bid-amount"
                    id="bid"
                    name="amount"
                    onChange={onUpdate}
                    data-fuel-input
                    data-fuel={fuelId}
                  />
                </div>
              </div>
            </div>
            <div className="column">
              <div className="field">
                <label className="label" htmlFor="bid">Minimum Bid</label>
                <div className="control auction-bidding__input has-icons-left">
                  <input
                    type="number"
                    step="0.25"
                    min="0"
                    className="input qa-auction-bid-min_amount"
                    id="minimumBid"
                    name="min_amount"
                    onChange={onUpdate}
                    data-fuel-input
                    data-fuel={fuelId}
                  />
                  <span className="icon is-small is-left"><i className="fas fa-dollar-sign"></i></span>
                </div>
              </div>
            </div>
          </div>
        </div>
        { isMultiProduct
          ? <div className="column is-narrow">
              <label className="checkbox">
                <input type="checkbox" className="qa-auction-bid-allow_split" name="allow_split" defaultChecked={true} data-fuel-input data-fuel={fuelId}/> Split?
                <i className="auction__split-bid-help fas fa-question-circle has-text-gray-3 has-margin-left-sm" action-label="Allow Split with Other Supplier Offers"></i>
              </label>
            </div>
          : <input type="hidden" className="qa-auction-bid-allow_split" name="allow_split" value="true" />
        }
      </div>
      <div className="auction-bidding__vessels columns">
        <div className="column is-narrow">
          <span className="has-text-weight-bold">Vessels:</span>
        </div>
        <div className="column columns">
          { _.map(vesselFuels, (vesselFuel) => {
              const vessel = vesselFuel.vessel;
              const quantity = vesselFuel.quantity;
              const existingBid = _.chain(auctionPayload)
                .get(`bid_history`)
                .filter('active')
                .find({vessel_fuel_id: `${vesselFuel.id}`})
                .value();
              const currentBidAmount = _.get(existingBid, `amount`);
              const minimumBidAmount = _.get(existingBid, `min_amount`);

              return (
                <div className="column is-narrow" key={vesselFuel.id}>
                  <label htmlFor={`auction-bid_vessel_fuel-${vesselFuel.id}`} className='auction-bidding__vessel-selection label' key={vessel.name}>
                    <input
                      className={`checkbox qa-auction-bid-fuel-${fuelId}-vessel-${vessel.id} has-margin-right-sm`}
                      id={`auction-bid_vessel_fuel-${vesselFuel.id}`}
                      name={`auction-bid_vessel_fuel-${vesselFuel.id}`}
                      type="checkbox"
                      defaultChecked={true}
                      onChange={onUpdate}
                      data-fuel={fuelId}
                      data-vessel={vessel.id}
                      data-vessel-fuel={vesselFuel.id}
                    />
                    {vessel.name}
                    <span className="is-inline-block has-text-gray-3 has-text-weight-normal has-margin-left-xs"> &times; {quantity} MT</span>
                    <br/>
                    { existingBid
                      ? <div className="control has-margin-top-sm has-margin-bottom-xs">
                          <span className="tag is-gray-2 is-capitalized has-family-copy"><span className="qa-auction-bid-amount">{`$` + formatPrice(currentBidAmount)}</span> <span className="qa-auction-bid-min_amount has-margin-left-xs"> {minimumBidAmount ? `(Min $${formatPrice(minimumBidAmount)})` : ""}</span></span>
                        </div>
                      : <div className="control has-margin-top-sm has-margin-bottom-xs">
                            <span className="tag is-gray-2 has-family-copy has-text-weight-normal is-italic is-capitalized qa-auction-bid-no_existing ">No active bid</span>
                        </div>
                    }
                  </label>
                </div>
              );
            })
          }
        </div>
      </div>
    </div>
  );
};

export default BiddingFormProduct;
