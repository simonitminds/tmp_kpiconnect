import _ from 'lodash';
import React from 'react';
import InputField from '../input-field';
import DateTimeInput from '../date-time-input';

const FixtureDeliveryForm = (props) => {
  const {
    fixture,
    fixturePayloads,
    handleDeliverySubmit
  } = props;
  const auction = _
    .chain(fixturePayloads)
    .map(payload => payload.auction)
    .find({ 'id': fixture.auction_id })
    .value();

  const fuels = _
    .chain(auction.auction_vessel_fuels)
    .map((vf) => vf.fuel)
    .uniqBy('id')
    .value();

  return (
    <React.Fragment>
      <h1>Fixture {fixture.id}</h1>
      <form onSubmit={handleDeliverySubmit}>
        <div className="field">
          <label className="label">Delivered Vessel</label>
          <div className="field-body">
            <div className="control">
              <div className="select">
                <select
                  name="delivered_vessel"
                  className="qa-fixture-vessel_id"
                  defaultValue={fixture.vessel_id}>
                  <option value="">Select Vessel</option>
                  { _.map(auction.vessels, vessel => (
                    <option className={`qa-fixture-delivered_vessel_id-${vessel.id}`} key={vessel.id} value={vessel.id}>
                      {vessel.name}
                    </option>
                  )) }
                </select>
              </div>
            </div>
          </div>
        </div>

        <div className="field  ">
          <label className="label">Delivered Fuel</label>
          <div className="field-body">
            <div className="control">
              <div className="select">
                <select
                  name="delivered_fuel"
                  className="qa-fixture-fuel_id"
                  defaultValue={fixture.fuel_id}>
                  <option value="">Select Fuel</option>
                  { _.map(fuels, fuel => (
                    <option className={`qa-fixture-delivered_vessel_id-${fuel.id}`} key={fuel.id} value={fuel.id}>
                      {fuel.name}
                    </option>
                  )) }
                </select>
              </div>
            </div>
          </div>
        </div>

        <div className="field  ">
          <label className="label">Delivered Price</label>
          <div className="field-body">
            <div className="control">
              <input
                defaultValue={fixture.price}
                name="delivered_price"
                className="qa-fixture-price input" />
            </div>
          </div>
        </div>

        <div className="field  ">
          <label className="label">Delivered Quantity</label>
          <div className="field-body">
            <div className="control input__fuel-unit-container">
              <input
                defaultValue={fixture.quantity}
                name="delivered_quantity"
                className="qa-fixture-quantity input" />
              <span className="has-text-gray-3 has-margin-left-sm">MT</span>
            </div>
          </div>
        </div>

        <div className="field ">
          <label className="label">Delivered Supplier</label>
          <div className="field-body">
            <div className="control">
              <div className="select">
                <select
                  name="delivered_supplier"
                  className="qa-fixture-supplier_id"
                  defaultValue={fixture.supplier_id}>
                  <option value="">Select Supplier</option>
                  { _.map(auction.suppliers, supplier => (
                    <option className={`qa-fixture-delivered_vessel_id-${supplier.id}`} key={supplier.id} value={supplier.id}>
                      {supplier.name}
                    </option>
                  )) }
                </select>
              </div>
            </div>
          </div>
        </div>

        <DateTimeInput value={fixture.eta} fieldName={'delivered_eta'} model={'fixture'} field={'delivered_eta'} label={'Delivered ETA'} isHorizontal={false}/>

        <DateTimeInput value={fixture.etd} fieldName={'delivered_etd'} model={'fixture'} field={'delivered_etd'} label={'Delivered ETD'} isHorizontal={false}/>

        <div className="field">
          <div className="field-body">
            <div className="control">
              <button className="button is-primary">Confirm Delivery</button>
            </div>
          </div>
        </div>
      </form>
    </React.Fragment>
  );
}

export default FixtureDeliveryForm;
