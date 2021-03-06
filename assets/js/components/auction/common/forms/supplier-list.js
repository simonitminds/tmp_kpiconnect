import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import InputErrors from '../../../input-errors';


const SupplierList = (props) => {
  const { suppliers,
          selectedSuppliers,
          selectedPort,
          onToggleSupplier,
          onSelectAllSuppliers,
          onDeSelectAllSuppliers,
          errors
        } = props;

  const portLabel = () => {
    if (selectedPort) {
      return(`${selectedPort.name}, ${selectedPort.country}`);
    }
  };

  const isSelected = (id) => {
    if (_.includes(selectedSuppliers, id)) {
      return true;
    } else {
      return false;
    }
  }
  if (selectedPort) {
    return(
      <section className="auction-info is-gray-1">
        <div className="container">
          <div className="content"> <fieldset> <legend className="subtitle is-4">Invited Suppliers</legend>
              <p className="has-text-weight-bold is-5 has-margin-bottom-md">{portLabel()}</p>
              <div className="invite-selector__container qa-auction-suppliers">
                { _.map(suppliers, (supplier) => {
                    return(
                      <div className="invite-selector" key={supplier.id}>
                        <label className="invite-selector__checkbox" htmlFor={`invite-${supplier.id}`}>
                          <input
                            type="checkbox"
                            className={`qa-auction-supplier-${supplier.id}`}
                            name={`auction[suppliers][supplier-${supplier.id}]`}
                            id={`invite-${supplier.id}`}
                            value={supplier.id}
                            checked={!!isSelected(supplier.id)}
                            onChange={onToggleSupplier.bind(this, supplier.id)}
                          />
                          <span className="invite-selector__facade">
                            <FontAwesomeIcon icon={isSelected(supplier.id) ? "check" : "plus"} className="default-only" />
                            <FontAwesomeIcon icon="minus" className="hover-only" />
                          </span>
                          <span className="invite-selector__label">{supplier.name}</span>
                        </label>
                      </div>
                    );
                  })
                }
              </div>
              <InputErrors errors={errors.suppliers} />
              <div className="field has-addons">
                <div className="control">
                  <a id="selectAllSellers" className="button" onClick={onSelectAllSuppliers}>
                    <span className="icon is-small">
                      <FontAwesomeIcon icon="plus" />
                    </span>
                    <span className="is-inline-block has-margin-left-xs">Select All</span>
                  </a>
                </div>
                <div className="control">
                  <a id="deselectAllSellers" className="button" onClick={onDeSelectAllSuppliers}>
                    <span className="icon is-small">
                      <FontAwesomeIcon icon="minus" />
                    </span>
                    <span className="is-inline-block has-margin-left-xs">Deselect All</span>
                  </a>
                </div>
              </div>
              <input type="hidden" name="auction[suppliers]" value={selectedSuppliers || []} />
            </fieldset>
          </div>
        </div>
      </section>
    );
  } else {
    return(
      <section className="auction-info is-gray-1">
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4">Invited Suppliers</legend>
              <i className="qa-auction-select-port"> Select Port to invite Suppliers</i>
              <input type="hidden" name="auction[suppliers]" value={selectedSuppliers || []} />
            </fieldset>
          </div>
        </div>
      </section>)
  }
};

export default SupplierList;
