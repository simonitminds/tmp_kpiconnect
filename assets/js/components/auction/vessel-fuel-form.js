import React from 'react';
import _ from 'lodash';
import InputField from '../input-field';

export default class VesselFuelForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedVessels: [],
      selectedFuels: []
    }
  }

  addVessel(ev) {
    const selectedElement = ev.target
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
    const { auction, vessels, fuels, vessel_fuels } = this.props;
    const availableVessels = _.reject(vessels, (v) => {
      return _.some(this.state.selectedVessels, (sv) => v.id == sv);
    });
    const availableFuels = _.reject(fuels, (f) => {
      return _.some(this.state.selectedFuels, (sf) => f.id == sf);
    });
    const renderVessel = (vessel_id) => {
      const vessel = _.find(vessels, (v) => v.id == vessel_id);
      return (
        <div className={`qa-auction-vessel-${vessel.id}`} key={vessel.id}>
          {vessel.name}, {vessel.imo}
          <button onClick={(ev) => {
              this.removeVessel(vessel.id);
              ev.preventDefault();
            }}>
            Remove
          </button>
        </div>
      );
    }
    const renderFuel = (fuel_id) => {
      const fuel = _.find(fuels, (f) => f.id == fuel_id);
      return(
        <div className={`qa-auction-vessel-${fuel.id}`} key={fuel.id}>
          {fuel.name}
          <button onClick={(ev) => {
              this.removeFuel(fuel.id);
              ev.preventDefault();
          }}>
            Remove
          </button>
          {_.map(this.state.selectedVessels, (vessel_id) => renderFuelQuantityInput(vessel_id, fuel.id))}
        </div>
      )
    }

    const renderFuelQuantityInput = (vessel_id, fuel_id) => {
      const vessel = _.find(vessels, (v) => v.id == vessel_id);
      return(
        <div>
          <InputField model={'auction'}
                      field={`auction_vessel_fuels][${fuel_id}][${vessel.id}`}
                      value=""
                      isHorizontal={true}
                      opts={{type: 'number', label: `${vessel.name}`, name: `vessel_fuel-${fuel_id}-quantity`}} />
        </div>
      )
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
                  <div className="field-body">
                    <div className="control">
                      <div className="select is-fullwidth">
                        <select
                          className="qa-auction-select-vessel"
                          onChange={this.addVessel.bind(this)}
                          defaultValue=""
                        >
                          <option disabled value="" >
                            Please select
                          </option>
                          {_.map(availableVessels, vessel => (
                            <option key={vessel.id} value={vessel.id}>
                              {vessel.name}, {vessel.imo}
                            </option>
                          ))}
                      </select>
                      </div>
                    </div>
                    <div className="qa-auction-selected-vessels">
                      {_.map(this.state.selectedVessels, renderVessel)}
                    </div>
                  </div>
                </div>
              </fieldset>
            </div>
          </div>
        </section>

        <section className="auction-info"> {/* Fuels info */}
          <div className="container">
            <div className="content">
              <fieldset>
                <legend className="subtitle is-4" >Fuels</legend>
                {this.state.selectedVessels.length === 0 ?
                 <i className="qa-auction-select-fuel"> Select Vessels to add Fuels</i>
                :
                <div className="field is-horizontal">
                  <div className="field-label">
                    <label htmlFor="auction_fuel_id" className="label">
                      Fuel Name
                    </label>
                  </div>
                  <div className="field-body">
                    <div className="control">
                      <div className="select is-fullwidth">
                        <select
                          className="qa-auction-select-fuel"
                          onChange={this.addFuel.bind(this)}
                          defaultValue=""
                        >
                          <option disabled value="">
                            Please Select
                          </option>
                          {_.map(availableFuels, fuel => (
                            <option key={fuel.id} value={fuel.id}>
                              {fuel.name}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
                }
              </fieldset>
              <fieldset>
                <div className="qa-auction-selected-vessels-fuel_quantities">
                  {_.map(this.state.selectedFuels, renderFuel)}
                </div>
              </fieldset>
            </div>
          </div>
        </section>
      </div>
    );
  }
}
