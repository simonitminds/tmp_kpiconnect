import React from 'react';
import _ from 'lodash';
import { formatPrice } from '../../utilities';
import CheckBoxField from '../check-box-field';
import MediaQuery from 'react-responsive';

const BiddingFormProduct = ({fuel, auctionPayload, onRevoke, onUpdate}) => {
  const isMultiProduct = _.get(auctionPayload, 'auction.fuels', []).length > 1;

  const {id: fuelId, name} = fuel;
  const existingBid = _.chain(auctionPayload)
    .get(`bid_history`)
    .filter('active')
    .find({fuel_id: fuelId})
    .value();
  const currentBidAmount = _.get(existingBid, `amount`);
  const minimumBidAmount = _.get(existingBid, `min_amount`);
  const allowSplit = _.get(existingBid, 'allow_split', true);

  const vesselFuels = _.chain(auctionPayload)
    .get('auction.auction_vessel_fuels')
    .filter((avf) => avf.fuel_id == fuelId)
    .value();
  const totalQuantity = _.sumBy(vesselFuels, (vf) => vf.quantity);

  const confirmBidCancellation = (ev) => {
    ev.preventDefault();
    return confirm('Are you sure you want to cancel your bid for this product?') ? onRevoke(auction.id, fuelId) : false;
  };


  return(
    <div className="auction-bidding__product-group has-margin-bottom-md">
      <div className="columns is-desktop has-margin-bottom-xs">
        <div className="column is-one-quarter-desktop">
          <strong>{name}</strong><br/>
          <span className="has-text-gray-3">&times; {totalQuantity} MT </span>
          { existingBid
            ? <div className="tags has-addons has-margin-top-xs">
                <div className="tag is-success"><i className="fas fa-check"></i></div>
                <div className="tag revoke-bid__status is-white">Bid Active</div>
                <span className={`tag revoke-bid__button qa-auction-product-${fuelId}-revoke`} onClick={confirmBidCancellation} tabIndex="-1"><i className="fas fa-minus"></i></span>
                <input type="hidden" name="existing_bid" value="true" data-fuel-input data-fuel={fuelId} />
              </div>
            : <div className="tags has-addons has-margin-top-xs">
                <div className="tag is-gray-3"><i className="fas fa-times"></i></div>
                <div className="tag is-white revoke-bid__status">No Active Bid</div>
              </div>
          }
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
                <p className="help auction-bidding__label-addendum">Current: {currentBidAmount ? `$` + formatPrice(currentBidAmount) : '—'}</p>
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
                <p className="help auction-bidding__label-addendum">Current: {minimumBidAmount ? `$` + formatPrice(minimumBidAmount) : '—'}</p>
              </div>
            </div>
          </div>
        </div>
        { isMultiProduct
          ? <div className="column is-narrow">
              <label className="checkbox">
                <input type="checkbox" className="qa-auction-bid-allow_split" name="allow_split" defaultChecked={allowSplit} data-fuel-input data-fuel={fuelId}/> Split?
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
