import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import InputField from '../../../input-field';
import InputErrors from '../../../input-errors';
import DateTimeInput from '../../../date-time-input';

export default class VesselFuelForm extends React.Component {
  constructor(props) {
    super(props);

    const vesselFuels = this.props.vesselFuels;
    const selectedVessels = _.chain(vesselFuels).map('vessel_id').uniq().filter().value();
    const selectedFuels = _.chain(vesselFuels).map('fuel_id').uniq().filter().value();
    this.state = {
      selectedVessels: selectedVessels,
      selectedFuels: selectedFuels
    }
  }

  addVessel(ev) {
    const selectedElement = ev.target;
    const vessel_id = selectedElement.value;
    this.setState((previousState) => ({
      selectedVessels: _.uniq([...previousState.selectedVessels, vessel_id])
    }));
    selectedElement.value = "";
  }

  removeVessel(vessel_id) {
    this.setState((previousState) => ({
      selectedVessels: _.reject(previousState.selectedVessels, (v) => v == vessel_id)
    }));
  }

  addFuel(ev) {
    const selectedElement = ev.target;
    const fuel_id = selectedElement.value;
    this.setState((previousState) => ({
      selectedFuels: _.uniq([...previousState.selectedFuels, fuel_id])
    }));
    selectedElement.value = "";
  }

  removeFuel(fuel_id) {
    this.setState((previousState) => ({
      selectedFuels: _.reject(previousState.selectedFuels, (f) => f == fuel_id)
    }));
  }

  render() {
    const { auction, errors, vessels, fuels, vesselFuels, portId, ports } = this.props;
    const availableVessels = _.reject(vessels, (v) => {
      return _.some(this.state.selectedVessels, (sv) => v.id == sv);
    });
    const availableFuels = _.reject(fuels, (f) => {
      return _.some(this.state.selectedFuels, (sf) => f.id == sf);
    });

    const initialQuantityForVesselFuel = (vessel_id, fuel_id) => {
      const vesselFuel = _.find(vesselFuels, {vessel_id: vessel_id, fuel_id: fuel_id});
      return vesselFuel ? vesselFuel.quantity : 0;
    };

    const renderVessel = (vessel_id) => {
      const vessel = _.find(vessels, (v) => v.id == vessel_id);
      const initialVesselFuels = _.filter(vesselFuels, {vessel_id: vessel_id});
      const initialETA = _.chain(initialVesselFuels).map('eta').min().value() || auction.eta;
      const initialETD = _.chain(initialVesselFuels).map('etd').min().value() || auction.etd;
      return (
        <div className={`is-flex is-flex-wrapped qa-auction-vessel-${vessel.id}`} key={vessel.id}>
          <span className="selected-list__item-title">{vessel.name}, {vessel.imo}</span>
          <span className="selected-list__item-delete" onClick={(ev) => {
              this.removeVessel(vessel.id);
              ev.preventDefault();
            }}>
            <FontAwesomeIcon icon="times" />
          </span>
          <input type="hidden" name={`auction[vessels][${vessel.id}][selected]`} value={true} />
          <DateTimeInput label="ETA" value={initialETA} portId={portId} ports={ports} fieldName={`auction[vessels][${vessel.id}][eta]`} model="vessel" field="eta" />
          <InputErrors errors={errors.auction_vessel_fuels && errors.auction_vessel_fuels[0] ? errors.auction_vessel_fuels[0].eta : ""} />
          <DateTimeInput label="ETD" value={initialETD} portId={portId} ports={ports} fieldName={`auction[vessels][${vessel.id}][etd]`} model="vessel" field="etd" />
          <InputErrors errors={errors.auction_vessel_fuels && errors.auction_vessel_fuels[0] ? errors.auction_vessel_fuels[0].etd : ""} />
        </div>
      );
    }
    const renderFuel = (fuel_id) => {
      const fuel = _.find(fuels, (f) => f.id == fuel_id);
      return(
        <div className={`is-flex is-flex-wrapped qa-auction-fuel-${fuel.id}`} key={fuel.id}>
          {fuel.name}
          <span className="selected-list__item-delete" onClick={(ev) => {
              this.removeFuel(fuel.id);
              ev.preventDefault();
            }}>
            <FontAwesomeIcon icon="times" />
          </span>
          <br/>
          <div className="selected-list__sublist">
            {_.map(this.state.selectedVessels, (vessel_id) => renderFuelQuantityInput(vessel_id, fuel.id))}
          </div>
          <input type="hidden" name="auction[fuels][]" value={fuel.id} />
        </div>
      )
    }
    const renderFuelQuantityInput = (vessel_id, fuel_id) => {
      const vessel = _.find(vessels, (v) => v.id == vessel_id);
      const initialQuantity = initialQuantityForVesselFuel(vessel.id, fuel_id);
      return(
        <React.Fragment>
          <InputField
            key={`${fuel_id}-${vessel_id}`}
            model={'auction'}
            field={`auction_vessel_fuels][${fuel_id}][${vessel.id}`}
            value={initialQuantity}
            isHorizontal={true}
            fuelUnitInput={true}
            opts={{type: 'number', label: `${vessel.name}`, name: `vessel_fuel-${fuel_id}-quantity`, className: `input--fuel-vol qa-auction-vessel-${vessel.id}-fuel-${fuel_id}-quantity`}}
          />
          <InputErrors errors={errors.auction_vessel_fuels && errors.auction_vessel_fuels[0] ? errors.auction_vessel_fuels[0].quantity : ""} />
        </React.Fragment>
      );
    }

    return(
      <div>
        <section className="auction-info"> {/* Vessels info */}
          <div className="container">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Vessels</legend>
                <div className="field is-horizontal">
                  <div className="field-label">
                    <label htmlFor="auction_vessel_id" className="label">
                      Vessel Name
                    </label>
                  </div>
                  <div className="field-body field-body--select">
                    <div className="selected-list selected-list--vessels box qa-auction-selected-vessels">
                      {_.map(this.state.selectedVessels, renderVessel)}
                    </div>
                    <div className="control has-icons-left has-margin-right-none">
                      <div className="select is-fullwidth">
                        <select
                          className="qa-auction-select-vessel"
                          onChange={this.addVessel.bind(this)}
                          defaultValue=""
                        >
                          <option disabled value="" >
                            Add a Vessel
                          </option>
                          {_.map(availableVessels, vessel => (
                            <option key={vessel.id} value={vessel.id} id={vessel.id}>
                              {vessel.name}, {vessel.imo}
                            </option>
                          ))}
                      </select>
                      <div className="icon is-small is-left">
                        <FontAwesomeIcon icon="plus" />
                      </div>
                      </div>
                    </div>
                  </div>
                </div>
                { errors.auction_vessel_fuels && errors.auction_vessel_fuels[0] == "No auction vessel fuels set" ?
                    <InputErrors errors={errors.auction_vessel_fuels} />
                    :
                    ""
                }
              </fieldset>
            </div>
          </div>
        </section>

        <section className="auction-info is-gray-1"> {/* Fuels info */}
          <div className="container">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Fuels</legend>
                {this.state.selectedVessels.length === 0 ?
                 <i className="qa-auction-select-fuel"> Select Vessels to add Fuels</i>
                    :
                <React.Fragment>
                <div className="field is-horizontal">
                  <div className="field-label">
                    <label htmlFor="auction_fuel_id" className="label">
                      Fuel Name
                    </label>
                  </div>
                  <div className="field-body field-body--select">
                    <div className="box selected-list selected-list--fuels qa-auction-selected-vessels-fuel_quantities">
                      {_.map(this.state.selectedFuels, renderFuel)}
                    </div>
                    <div className="control has-icons-left has-margin-right-none">
                      <div className="select is-fullwidth">
                        <select
                          className="qa-auction-select-fuel"
                          onChange={this.addFuel.bind(this)}
                          defaultValue=""
                        >
                          <option disabled value="">
                            Add a Fuel
                          </option>
                          {_.map(availableFuels, fuel => (
                            <option key={fuel.id} value={fuel.id}>
                              {fuel.name}
                            </option>
                          ))}
                        </select>
                        <div className="icon is-small is-left">
                          <FontAwesomeIcon icon="plus" />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                    <InputErrors errors={errors.auction_vessel_fuels ? errors.auction_vessel_fuels[0].fuel_id : ""} />
                </React.Fragment>
                }
              </fieldset>
            </div>
          </div>
        </section>
      </div>
    );
  }
}
