import React from 'react';
import _ from 'lodash';
import InputField from '../input-field';

export default class VesselFuelForm extends React.Component {
  constructor(props) {
    super(props);

    const vesselFuels = this.props.vessel_fuels;
    const selectedVessels = _.chain(vesselFuels).map('vessel_id').uniq().filter().value();
    const selectedFuels = _.chain(vesselFuels).map('fuel_id').uniq().filter().value();
    this.state = {
      selectedVessels: selectedVessels,
      selectedFuels: selectedFuels
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
    const initialQuantityForVesselFuel = (vessel_id, fuel_id) => {
      const vesselFuel = _.find(vessel_fuels, {vessel_id: vessel_id, fuel_id: fuel_id});
      return vesselFuel && vesselFuel.quantity;
    };
    const availableVessels = _.reject(vessels, (v) => {
      return _.some(this.state.selectedVessels, (sv) => v.id == sv);
    });
    const availableFuels = _.reject(fuels, (f) => {
      return _.some(this.state.selectedFuels, (sf) => f.id == sf);
    });

    const renderVessel = (vessel_id) => {
      const vessel = _.find(vessels, (v) => v.id == vessel_id);
      return (
        <div className={`is-flex qa-auction-vessel-${vessel.id}`} key={vessel.id}>
          {vessel.name}, {vessel.imo}
          <span className="selected-list__item-delete" onClick={(ev) => {
              this.removeVessel(vessel.id);
              ev.preventDefault();
            }}>
            <i className="fas fa-times"></i>
          </span>
          <input type="hidden" name="auction[vessels][]" value={vessel.id} />
        </div>
      );
    }
    const renderFuel = (fuel_id) => {
      const fuel = _.find(fuels, (f) => f.id == fuel_id);
      return(
        <div className={`is-flex is-flex-wrapped qa-auction-vessel-${fuel.id}`} key={fuel.id}>
          {fuel.name}
          <span className="selected-list__item-delete" onClick={(ev) => {
              this.removeFuel(fuel.id);
              ev.preventDefault();
            }}>
            <i className="fas fa-times"></i>
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
          <InputField
            key={`${fuel_id}-${vessel_id}`}
            model={'auction'}
            field={`auction_vessel_fuels][${fuel_id}][${vessel.id}`}
            value={initialQuantity}
            isHorizontal={true}
            opts={{type: 'number', label: `${vessel.name}`, name: `vessel_fuel-${fuel_id}-quantity`, className: `qa-auction-vessel-${vessel.id}-fuel-${fuel_id}-quantity`}}
            />
      )
    }

    return(
      <div>
        <section className="auction-info is-gray-1"> {/* Vessels info */}
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
                  <div className="field-body field-body--wrapped">
                  <div className="selected-list selected-list--vessels box qa-auction-selected-vessels">
                    {_.map(this.state.selectedVessels, renderVessel)}
                  </div>
                  <span className="break"></span>
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
                        <i className="fas fa-plus"></i>
                      </div>
                      </div>
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
                  <div className="field-body field-body--wrapped">
                    <div className="box selected-list selected-list--fuels qa-auction-selected-vessels-fuel_quantities">
                      {_.map(this.state.selectedFuels, renderFuel)}
                    </div>
                    <span className="break"></span>
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
                          <i className="fas fa-plus"></i>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                }
              </fieldset>
            </div>
          </div>
        </section>
      </div>
    );
  }
}
