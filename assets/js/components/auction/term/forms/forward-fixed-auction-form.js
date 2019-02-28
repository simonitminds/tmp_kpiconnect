import React from 'react';
import _ from 'lodash';
import moment from 'moment';
import InputField from '../../../input-field';
import CheckBoxField from '../../../check-box-field';
import DateInput from '../../../date-input';
import TimeInput from '../../../time-input';
import { portLocalTime } from '../../../../utilities';
import SupplierList  from '../../common/forms/supplier-list';
import TermVesselFormSection from './term-vessel-form-section';
import TermFuelFormSection from './term-fuel-form-section';
import PortSelectFormSection from '../../common/forms/port-select-form-section';
import AdditionalInfoFormSection from '../../common/forms/additional-info-form-section';
import AuctionDetailsFormSection from '../../common/forms/auction-details-form-section';

const ForwardFixedAuctionForm = (props) => {
  const {
    auction,
    errors,
    type,
    deselectAllSuppliers,
    credit_margin_amount,
    eta_date,
    eta_time,
    etd_date,
    etd_time,
    fuels,
    ports,
    scheduled_start_date,
    scheduled_start_time,
    selectAllSuppliers,
    selectPort,
    selectAuctionType,
    selectedSuppliers,
    suppliers,
    toggleSupplier,
    updateDate,
    updateInformation,
    updateInformationFromCheckbox,
    vessels,
  } = props;

  const port_id = auction.port_id ? auction.port_id : "";
  const selectedPort = _.chain(ports)
        .filter(['id', auction.port_id])
        .first()
        .value();

  return (
    <React.Fragment>
      <PortSelectFormSection auction={auction}
                             errors={errors}
                             port_id={port_id}
                             ports={ports}
                             hasDurationAndTerminal={true}
                             selectPort={selectPort}
                             updateDate={updateDate}
                             updateInformation={updateInformation} />

      <SupplierList onDeSelectAllSuppliers={deselectAllSuppliers}
                    onSelectAllSuppliers={selectAllSuppliers}
                    onToggleSupplier={toggleSupplier}
                    selectedPort={selectedPort}
                    selectedSuppliers={selectedSuppliers}
                    suppliers={suppliers}
                    errors={errors} />


      <TermVesselFormSection auction={auction}
                             errors={errors}
                             vessels={vessels}
                             portId={port_id}
                             ports={ports} />

      <TermFuelFormSection auction={auction} errors={errors} fuels={fuels} updateInformation={updateInformation} updateInformationFromCheckbox={updateInformationFromCheckbox} />

      <AdditionalInfoFormSection auction={auction} errors={errors} updateInformation={updateInformation} isTermAuction={true }/>

      <AuctionDetailsFormSection auction={auction}
                                 errors={errors}
                                 credit_margin_amount={credit_margin_amount}
                                 isTermAuction={true}
                                 updateInformation={updateInformation}
                                 updateInformationFromCheckbox={updateInformationFromCheckbox}
                                 updateDate={updateDate} />

    </React.Fragment>
  );
};

export default ForwardFixedAuctionForm;
